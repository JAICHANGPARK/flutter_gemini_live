import 'package:flutter/foundation.dart';

/// Service Level Objectives (SLOs) for evaluating the quantitative stability
/// and latency of a Gemini Live WebSocket connection.
class GeminiConnectionSlo {
  /// Minimum acceptable connection handshake success rate (`0.0` to `1.0`).
  /// Defaults to `0.99` (99.0%).
  final double minHandshakeSuccessRate;

  /// Maximum acceptable 95th-percentile WebSocket setup latency in milliseconds.
  /// Defaults to `1200.0` ms.
  final double maxSetupLatencyP95Ms;

  /// Maximum acceptable 95th-percentile Time-To-First-Audio (TTFA) latency in milliseconds.
  /// Defaults to `800.0` ms.
  final double maxTtfaP95Ms;

  /// Minimum acceptable session resumption/reconnection recovery rate (`0.0` to `1.0`).
  /// Defaults to `0.95` (95.0%).
  final double minRecoverySuccessRate;

  /// Maximum acceptable Mean Time To Recovery (MTTR) in milliseconds.
  /// Defaults to `2000.0` ms.
  final double maxMttrMs;

  /// Creates a [GeminiConnectionSlo] threshold specification.
  const GeminiConnectionSlo({
    this.minHandshakeSuccessRate = 0.99,
    this.maxSetupLatencyP95Ms = 1200.0,
    this.maxTtfaP95Ms = 800.0,
    this.minRecoverySuccessRate = 0.95,
    this.maxMttrMs = 2000.0,
  });
}

/// Quantitative report produced by [GeminiConnectionMetricsTracker.evaluateSlo].
class GeminiConnectionSloReport {
  /// The target SLO thresholds evaluated against.
  final GeminiConnectionSlo slo;

  /// Whether all evaluated metrics with recorded samples satisfy [slo].
  final bool isCompliant;

  /// Composite stability score from `0.0` to `100.0`.
  final double stabilityScore;

  /// Human-readable list of SLO violations, or empty if [isCompliant] is `true`.
  final List<String> violations;

  /// Snapshot of the quantitative metrics at evaluation time.
  final Map<String, dynamic> metricsSnapshot;

  /// Creates a [GeminiConnectionSloReport].
  const GeminiConnectionSloReport({
    required this.slo,
    required this.isCompliant,
    required this.stabilityScore,
    required this.violations,
    required this.metricsSnapshot,
  });

  /// Converts this SLO report into a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'isCompliant': isCompliant,
    'stabilityScore': stabilityScore,
    'violations': violations,
    'metrics': metricsSnapshot,
  };
}

/// Real-time quantitative connection stability and latency tracker for
/// Gemini Live API WebSocket sessions.
///
/// Tracks and computes Service Level Indicators (SLIs):
/// - **Handshake Success Rate (CSR)**: Successful `setupComplete` handshakes vs. total attempts.
/// - **Setup Latency**: WebSocket connection + `setupComplete` handshake duration (`avg`, `p50`, `p95`, `p99`).
/// - **Time-To-First-Audio (TTFA)**: Latency from user turn completion to the first model audio chunk (`avg`, `p50`, `p95`, `p99`).
/// - **Session Recovery Rate (SRR)**: Successful automatic reconnections after `GoAway` or abnormal close (`code != 1000`).
/// - **Mean Time To Recovery (MTTR)**: Average duration from unexpected disconnect/`GoAway` to re-established session.
/// - **Cumulative Uptime**: Total connected duration across the session lifecycle.
class GeminiConnectionMetricsTracker extends ChangeNotifier {
  final DateTime Function() _clock;
  final GeminiConnectionSlo slo;

  int _connectAttempts = 0;
  int _connectSuccesses = 0;
  int _connectFailures = 0;
  int _normalDisconnects = 0;
  int _abnormalDisconnects = 0;
  int _goAwayCount = 0;
  int _reconnectAttempts = 0;
  int _reconnectSuccesses = 0;
  int _resumedSessionsCount = 0;

  DateTime? _connectStartTime;
  DateTime? _connectedSince;
  DateTime? _disruptionStartTime;
  DateTime? _userTurnEndTime;
  Duration _accumulatedUptime = Duration.zero;

  final List<double> _setupLatenciesMs = [];
  final List<double> _ttfaLatenciesMs = [];
  final List<double> _recoveryLatenciesMs = [];

  /// Creates a [GeminiConnectionMetricsTracker] with optional custom [slo] thresholds
  /// and an injectable [clock] for deterministic unit testing.
  GeminiConnectionMetricsTracker({
    this.slo = const GeminiConnectionSlo(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Total number of connection attempts initiated.
  int get connectAttempts => _connectAttempts;

  /// Total number of connections that reached `setupComplete`.
  int get connectSuccesses => _connectSuccesses;

  /// Total number of connection attempts that failed or timed out.
  int get connectFailures => _connectFailures;

  /// Total number of clean disconnects (`closeCode == 1000` or manual disconnect).
  int get normalDisconnects => _normalDisconnects;

  /// Total number of abnormal disconnects (`closeCode != 1000`, e.g. `1006`).
  int get abnormalDisconnects => _abnormalDisconnects;

  /// Total number of server `GoAway` notices received.
  int get goAwayCount => _goAwayCount;

  /// Total number of automatic reconnection attempts scheduled.
  int get reconnectAttempts => _reconnectAttempts;

  /// Total number of automatic reconnections that succeeded.
  int get reconnectSuccesses => _reconnectSuccesses;

  /// Total number of connections established using a `SessionResumptionConfig` handle.
  int get resumedSessionsCount => _resumedSessionsCount;

  /// Handshake success rate (`0.0` to `1.0`). Returns `1.0` if no attempts have been made.
  double get handshakeSuccessRate =>
      _connectAttempts == 0 ? 1.0 : _connectSuccesses / _connectAttempts;

  /// Session recovery rate (`0.0` to `1.0`) for automatic reconnections.
  /// Returns `1.0` if no reconnection attempts have been triggered.
  double get recoverySuccessRate =>
      _reconnectAttempts == 0 ? 1.0 : _reconnectSuccesses / _reconnectAttempts;

  /// Recorded WebSocket setup latencies in milliseconds.
  List<double> get setupLatenciesMs => List.unmodifiable(_setupLatenciesMs);

  /// Recorded Time-To-First-Audio (TTFA) latencies in milliseconds.
  List<double> get ttfaLatenciesMs => List.unmodifiable(_ttfaLatenciesMs);

  /// Recorded reconnection recovery durations in milliseconds.
  List<double> get recoveryLatenciesMs =>
      List.unmodifiable(_recoveryLatenciesMs);

  /// Most recent setup handshake latency in milliseconds, or `null` if none recorded.
  double? get lastSetupLatencyMs =>
      _setupLatenciesMs.isEmpty ? null : _setupLatenciesMs.last;

  /// Average setup handshake latency in milliseconds.
  double get averageSetupLatencyMs => _mean(_setupLatenciesMs);

  /// 50th-percentile (median) setup handshake latency in milliseconds.
  double get p50SetupLatencyMs => percentile(_setupLatenciesMs, 50);

  /// 95th-percentile setup handshake latency in milliseconds.
  double get p95SetupLatencyMs => percentile(_setupLatenciesMs, 95);

  /// 99th-percentile setup handshake latency in milliseconds.
  double get p99SetupLatencyMs => percentile(_setupLatenciesMs, 99);

  /// Most recent Time-To-First-Audio (TTFA) latency in milliseconds, or `null` if none recorded.
  double? get lastTtfaMs =>
      _ttfaLatenciesMs.isEmpty ? null : _ttfaLatenciesMs.last;

  /// Average Time-To-First-Audio (TTFA) latency in milliseconds.
  double get averageTtfaMs => _mean(_ttfaLatenciesMs);

  /// 50th-percentile (median) Time-To-First-Audio (TTFA) latency in milliseconds.
  double get p50TtfaMs => percentile(_ttfaLatenciesMs, 50);

  /// 95th-percentile Time-To-First-Audio (TTFA) latency in milliseconds.
  double get p95TtfaMs => percentile(_ttfaLatenciesMs, 95);

  /// 99th-percentile Time-To-First-Audio (TTFA) latency in milliseconds.
  double get p99TtfaMs => percentile(_ttfaLatenciesMs, 99);

  /// Mean Time To Recovery (MTTR) in milliseconds across completed reconnections.
  double get mttrMs => _mean(_recoveryLatenciesMs);

  /// Total cumulative connected uptime across the session lifecycle.
  Duration get totalUptime {
    final active = _connectedSince != null
        ? _clock().difference(_connectedSince!)
        : Duration.zero;
    return _accumulatedUptime + (active.isNegative ? Duration.zero : active);
  }

  /// Composite stability score from `0.0` to `100.0` weighting handshake reliability (40%),
  /// recovery reliability (30%), setup latency compliance (15%), and TTFA latency compliance (15%).
  double get stabilityScore {
    final handshakeComponent = handshakeSuccessRate.clamp(0.0, 1.0) * 40.0;
    final recoveryComponent = recoverySuccessRate.clamp(0.0, 1.0) * 30.0;

    double setupComponent = 15.0;
    if (_setupLatenciesMs.isNotEmpty && slo.maxSetupLatencyP95Ms > 0) {
      final ratio = p95SetupLatencyMs / slo.maxSetupLatencyP95Ms;
      setupComponent = ratio <= 1.0
          ? 15.0
          : (15.0 * (1.0 / ratio)).clamp(0.0, 15.0);
    }

    double ttfaComponent = 15.0;
    if (_ttfaLatenciesMs.isNotEmpty && slo.maxTtfaP95Ms > 0) {
      final ratio = p95TtfaMs / slo.maxTtfaP95Ms;
      ttfaComponent = ratio <= 1.0
          ? 15.0
          : (15.0 * (1.0 / ratio)).clamp(0.0, 15.0);
    }

    return double.parse(
      (handshakeComponent + recoveryComponent + setupComponent + ttfaComponent)
          .clamp(0.0, 100.0)
          .toStringAsFixed(2),
    );
  }

  /// Marks the start of a WebSocket connection handshake attempt.
  void recordConnectStart({
    bool isReconnect = false,
    bool hasResumptionHandle = false,
  }) {
    final now = _clock();
    _connectAttempts++;
    _connectStartTime = now;
    if (isReconnect) {
      _reconnectAttempts++;
      _disruptionStartTime ??= now;
    }
    if (hasResumptionHandle) {
      _resumedSessionsCount++;
    }
    notifyListeners();
  }

  /// Marks a successful WebSocket connection and `setupComplete` handshake.
  void recordConnectSuccess({double? explicitLatencyMs}) {
    final now = _clock();
    _connectSuccesses++;
    _connectedSince = now;

    if (explicitLatencyMs != null) {
      _setupLatenciesMs.add(explicitLatencyMs);
    } else if (_connectStartTime != null) {
      final elapsedMs =
          now.difference(_connectStartTime!).inMicroseconds / 1000.0;
      _setupLatenciesMs.add(elapsedMs < 0 ? 0.0 : elapsedMs);
    }
    _connectStartTime = null;

    if (_disruptionStartTime != null) {
      _reconnectSuccesses++;
      final recoveryMs =
          now.difference(_disruptionStartTime!).inMicroseconds / 1000.0;
      _recoveryLatenciesMs.add(recoveryMs < 0 ? 0.0 : recoveryMs);
      _disruptionStartTime = null;
    }
    notifyListeners();
  }

  /// Marks a failed WebSocket connection or setup timeout.
  void recordConnectFailure() {
    _connectFailures++;
    _connectStartTime = null;
    notifyListeners();
  }

  /// Records a server `GoAway` notice and starts tracking recovery time.
  void recordGoAway() {
    _goAwayCount++;
    _disruptionStartTime ??= _clock();
    notifyListeners();
  }

  /// Records a WebSocket disconnection.
  ///
  /// When [isAbnormal] is `true` (e.g., `closeCode != 1000` and not manually disconnected),
  /// increments [abnormalDisconnects] and starts the recovery timer for MTTR calculation.
  void recordDisconnect({required bool isAbnormal}) {
    final now = _clock();
    if (_connectedSince != null) {
      final delta = now.difference(_connectedSince!);
      if (!delta.isNegative) {
        _accumulatedUptime += delta;
      }
      _connectedSince = null;
    }
    if (isAbnormal) {
      _abnormalDisconnects++;
      _disruptionStartTime ??= now;
    } else {
      _normalDisconnects++;
      _disruptionStartTime = null;
    }
    notifyListeners();
  }

  /// Marks the moment the user finishes a speech or text turn to begin measuring TTFA.
  void recordUserTurnSubmitted() {
    _userTurnEndTime = _clock();
  }

  /// Records the arrival of the first model response audio chunk for the current turn.
  ///
  /// If [explicitTtfaMs] is provided, records it directly; otherwise computes
  /// the elapsed duration since [recordUserTurnSubmitted].
  void recordFirstModelAudio({double? explicitTtfaMs}) {
    if (explicitTtfaMs != null) {
      _ttfaLatenciesMs.add(explicitTtfaMs);
      _userTurnEndTime = null;
      notifyListeners();
      return;
    }
    if (_userTurnEndTime != null) {
      final elapsedMs =
          _clock().difference(_userTurnEndTime!).inMicroseconds / 1000.0;
      _ttfaLatenciesMs.add(elapsedMs < 0 ? 0.0 : elapsedMs);
      _userTurnEndTime = null;
      notifyListeners();
    }
  }

  /// Evaluates current quantitative metrics against [customSlo] (or [slo]).
  GeminiConnectionSloReport evaluateSlo([GeminiConnectionSlo? customSlo]) {
    final target = customSlo ?? slo;
    final violations = <String>[];

    if (_connectAttempts > 0 &&
        handshakeSuccessRate < target.minHandshakeSuccessRate) {
      violations.add(
        'Handshake success rate (${(handshakeSuccessRate * 100).toStringAsFixed(1)}%) '
        'is below SLO (${(target.minHandshakeSuccessRate * 100).toStringAsFixed(1)}%).',
      );
    }

    if (_setupLatenciesMs.isNotEmpty &&
        p95SetupLatencyMs > target.maxSetupLatencyP95Ms) {
      violations.add(
        'Setup latency p95 (${p95SetupLatencyMs.toStringAsFixed(1)} ms) '
        'exceeds SLO (${target.maxSetupLatencyP95Ms.toStringAsFixed(1)} ms).',
      );
    }

    if (_ttfaLatenciesMs.isNotEmpty && p95TtfaMs > target.maxTtfaP95Ms) {
      violations.add(
        'TTFA p95 (${p95TtfaMs.toStringAsFixed(1)} ms) '
        'exceeds SLO (${target.maxTtfaP95Ms.toStringAsFixed(1)} ms).',
      );
    }

    if (_reconnectAttempts > 0 &&
        recoverySuccessRate < target.minRecoverySuccessRate) {
      violations.add(
        'Session recovery rate (${(recoverySuccessRate * 100).toStringAsFixed(1)}%) '
        'is below SLO (${(target.minRecoverySuccessRate * 100).toStringAsFixed(1)}%).',
      );
    }

    if (_recoveryLatenciesMs.isNotEmpty && mttrMs > target.maxMttrMs) {
      violations.add(
        'Mean Time To Recovery (${mttrMs.toStringAsFixed(1)} ms) '
        'exceeds SLO (${target.maxMttrMs.toStringAsFixed(1)} ms).',
      );
    }

    return GeminiConnectionSloReport(
      slo: target,
      isCompliant: violations.isEmpty,
      stabilityScore: stabilityScore,
      violations: violations,
      metricsSnapshot: toJson(),
    );
  }

  /// Formats a human-readable summary of setup latency (e.g., `"310 ms (p95: 480 ms)"`).
  String formatSetupLatency() {
    if (_setupLatenciesMs.isEmpty) return 'N/A';
    return '${averageSetupLatencyMs.round()} ms (p95: ${p95SetupLatencyMs.round()} ms)';
  }

  /// Formats a human-readable summary of TTFA latency (e.g., `"240 ms (p95: 390 ms)"`).
  String formatTtfaLatency() {
    if (_ttfaLatenciesMs.isEmpty) return 'N/A';
    return '${averageTtfaMs.round()} ms (p95: ${p95TtfaMs.round()} ms)';
  }

  /// Formats a human-readable summary of stability and handshake/recovery rates.
  String formatStabilitySummary() {
    final csr = (handshakeSuccessRate * 100).toStringAsFixed(1);
    return '${stabilityScore.toStringAsFixed(1)}/100 (CSR: $csr%)';
  }

  /// Resets all recorded connection stability and latency metrics.
  void reset() {
    _connectAttempts = 0;
    _connectSuccesses = 0;
    _connectFailures = 0;
    _normalDisconnects = 0;
    _abnormalDisconnects = 0;
    _goAwayCount = 0;
    _reconnectAttempts = 0;
    _reconnectSuccesses = 0;
    _resumedSessionsCount = 0;
    _connectStartTime = null;
    _connectedSince = null;
    _disruptionStartTime = null;
    _userTurnEndTime = null;
    _accumulatedUptime = Duration.zero;
    _setupLatenciesMs.clear();
    _ttfaLatenciesMs.clear();
    _recoveryLatenciesMs.clear();
    notifyListeners();
  }

  /// Exports all quantitative metrics as a structured Map for telemetry or JSON logging.
  Map<String, dynamic> toJson() => {
    'connectAttempts': _connectAttempts,
    'connectSuccesses': _connectSuccesses,
    'connectFailures': _connectFailures,
    'handshakeSuccessRate': handshakeSuccessRate,
    'normalDisconnects': _normalDisconnects,
    'abnormalDisconnects': _abnormalDisconnects,
    'goAwayCount': _goAwayCount,
    'reconnectAttempts': _reconnectAttempts,
    'reconnectSuccesses': _reconnectSuccesses,
    'recoverySuccessRate': recoverySuccessRate,
    'resumedSessionsCount': _resumedSessionsCount,
    'setupLatencyMs': {
      'count': _setupLatenciesMs.length,
      'avg': averageSetupLatencyMs,
      'p50': p50SetupLatencyMs,
      'p95': p95SetupLatencyMs,
      'p99': p99SetupLatencyMs,
    },
    'ttfaMs': {
      'count': _ttfaLatenciesMs.length,
      'avg': averageTtfaMs,
      'p50': p50TtfaMs,
      'p95': p95TtfaMs,
      'p99': p99TtfaMs,
    },
    'mttrMs': mttrMs,
    'uptimeMs': totalUptime.inMilliseconds,
    'stabilityScore': stabilityScore,
  };

  /// Computes the [p]-th percentile (`0` to `100`) of [samples].
  static double percentile(List<double> samples, double p) {
    if (samples.isEmpty) return 0.0;
    final sorted = List<double>.from(samples)..sort();
    if (sorted.length == 1) return sorted.first;
    final clampedP = p.clamp(0.0, 100.0) / 100.0;
    final pos = clampedP * (sorted.length - 1);
    final lower = pos.floor();
    final upper = pos.ceil();
    if (lower == upper) return sorted[lower];
    final weight = pos - lower;
    return sorted[lower] * (1.0 - weight) + sorted[upper] * weight;
  }

  static double _mean(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    var sum = 0.0;
    for (final v in samples) {
      sum += v;
    }
    return sum / samples.length;
  }
}
