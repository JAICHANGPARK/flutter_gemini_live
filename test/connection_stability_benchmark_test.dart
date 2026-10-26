import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('GeminiConnectionMetricsTracker — Quantitative SLI & SLO Evaluation', () {
    test('calculates handshake CSR, setup latency percentiles, TTFA, SRR, MTTR, and SLO compliance', () {
      var now = DateTime.utc(2026, 10, 26, 12, 0, 0);
      final tracker = GeminiConnectionMetricsTracker(
        clock: () => now,
        slo: const GeminiConnectionSlo(
          minHandshakeSuccessRate: 0.90,
          maxSetupLatencyP95Ms: 500.0,
          maxTtfaP95Ms: 400.0,
          minRecoverySuccessRate: 0.90,
          maxMttrMs: 1500.0,
        ),
      );

      // Initial state
      expect(tracker.connectAttempts, 0);
      expect(tracker.handshakeSuccessRate, 1.0);
      expect(tracker.recoverySuccessRate, 1.0);
      expect(tracker.stabilityScore, 100.0);
      expect(tracker.formatSetupLatency(), 'N/A');
      expect(tracker.formatTtfaLatency(), 'N/A');

      // 1. First connection attempt -> succeeds in 180ms
      tracker.recordConnectStart();
      now = now.add(const Duration(milliseconds: 180));
      tracker.recordConnectSuccess();
      expect(tracker.connectAttempts, 1);
      expect(tracker.connectSuccesses, 1);
      expect(tracker.lastSetupLatencyMs, 180.0);

      // 2. Turn 1 TTFA -> 210ms
      now = now.add(const Duration(seconds: 2));
      tracker.recordUserTurnSubmitted();
      now = now.add(const Duration(milliseconds: 210));
      tracker.recordFirstModelAudio();
      expect(tracker.lastTtfaMs, 210.0);

      // 3. Turn 2 TTFA -> 320ms
      now = now.add(const Duration(seconds: 3));
      tracker.recordUserTurnSubmitted();
      now = now.add(const Duration(milliseconds: 320));
      tracker.recordFirstModelAudio();
      expect(tracker.averageTtfaMs, closeTo(265.0, 0.01));
      expect(tracker.p50TtfaMs, closeTo(265.0, 0.01));
      expect(tracker.p95TtfaMs, closeTo(314.5, 0.1));

      // 4. Simulate abnormal disconnect (1006) + automatic reconnect with resumption handle in 650ms total
      now = now.add(const Duration(seconds: 5));
      tracker.recordDisconnect(isAbnormal: true);
      expect(tracker.abnormalDisconnects, 1);

      now = now.add(const Duration(milliseconds: 500)); // backoff wait
      tracker.recordConnectStart(isReconnect: true, hasResumptionHandle: true);
      now = now.add(const Duration(milliseconds: 150)); // setup handshake
      tracker.recordConnectSuccess();

      expect(tracker.reconnectAttempts, 1);
      expect(tracker.reconnectSuccesses, 1);
      expect(tracker.resumedSessionsCount, 1);
      expect(tracker.recoverySuccessRate, 1.0);
      expect(tracker.mttrMs, closeTo(650.0, 0.1));

      // Evaluate SLO report -> should be 100% compliant
      final report = tracker.evaluateSlo();
      expect(report.isCompliant, isTrue);
      expect(report.violations, isEmpty);
      expect(report.stabilityScore, 100.0);
      expect(report.toJson()['isCompliant'], isTrue);
      expect(tracker.formatSetupLatency(), contains('ms'));
      expect(tracker.formatTtfaLatency(), contains('ms'));
      expect(tracker.formatStabilitySummary(), contains('100.0/100'));

      // Clean disconnect accumulates uptime
      now = now.add(const Duration(seconds: 10));
      tracker.recordDisconnect(isAbnormal: false);
      expect(tracker.normalDisconnects, 1);
      expect(tracker.totalUptime.inSeconds, 20);
    });

    test('detects SLO violations when handshake fails, latency spikes, or recovery degrades', () {
      final tracker = GeminiConnectionMetricsTracker(
        slo: const GeminiConnectionSlo(
          minHandshakeSuccessRate: 0.95,
          maxSetupLatencyP95Ms: 300.0,
          maxTtfaP95Ms: 250.0,
          minRecoverySuccessRate: 0.90,
          maxMttrMs: 1000.0,
        ),
      );

      // 1 success (slow: 800ms), 1 failure -> CSR = 50%
      tracker.recordConnectStart();
      tracker.recordConnectSuccess(explicitLatencyMs: 800.0);
      tracker.recordConnectStart();
      tracker.recordConnectFailure();

      // Slow TTFA: 600ms
      tracker.recordFirstModelAudio(explicitTtfaMs: 600.0);

      // Failed reconnect -> SRR = 0%
      tracker.recordGoAway();
      tracker.recordConnectStart(isReconnect: true);
      tracker.recordConnectFailure();

      final report = tracker.evaluateSlo();
      expect(report.isCompliant, isFalse);
      expect(report.violations.length, 4);
      expect(report.stabilityScore, lessThan(40.0));

      tracker.reset();
      expect(tracker.connectAttempts, 0);
      expect(tracker.connectFailures, 0);
      expect(tracker.goAwayCount, 0);
      expect(tracker.setupLatenciesMs, isEmpty);
      expect(tracker.ttfaLatenciesMs, isEmpty);
    });
  });

  group('Chaos & Fault-Injection Benchmark — GeminiLiveSessionController', () {
    test('survives multi-drop network chaos (Code 1006 & GoAway) with 100% session resumption and zero transcript loss', () async {
      final channels = <_ChaosFakeChannel>[];
      var connectIndex = 0;

      final service = LiveService(
        apiKey: 'chaos-test-key',
        connector: (uri, headers) async {
          final ch = _ChaosFakeChannel();
          channels.add(ch);
          final currentIdx = ++connectIndex;
          unawaited(
            Future<void>.delayed(Duration.zero, () {
              ch.emitServerJson({
                'setupComplete': {'sessionId': 'sess-$currentIdx'},
              });
            }),
          );
          return ch;
        },
        setupTimeout: const Duration(seconds: 2),
      );

      final controller = GeminiLiveSessionController(
        liveService: service,
        reconnectPolicy: const GeminiLiveReconnectPolicy(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 40),
          backoffMultiplier: 1.5,
        ),
      );

      await controller.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          sessionResumption: SessionResumptionConfig(),
        ),
      );

      expect(controller.isConnected, isTrue);
      expect(controller.sessionId, 'sess-1');

      // Run 5 consecutive fault-injection cycles (alternating 1006 drops and GoAway notices)
      for (var cycle = 1; cycle <= 5; cycle++) {
        final activeChannel = channels.last;

        // Server issues a new session resumption handle
        final handle = 'handle-cycle-$cycle';
        activeChannel.emitServerJson({
          'sessionResumptionUpdate': {
            'newHandle': handle,
            'resumable': true,
          },
        });
        await _pumpEvents();
        expect(controller.latestSessionHandle, handle);

        // User sends a turn and model responds with audio
        controller.sendRealtimeText('User turn $cycle');
        activeChannel.emitServerJson({
          'serverContent': {
            'modelTurn': {
              'parts': [
                {
                  'inlineData': {
                    'mimeType': 'audio/pcm;rate=24000',
                    'data': base64Encode(Uint8List.fromList([1, 2, 3, 4])),
                  },
                },
                {'text': 'Model reply $cycle'},
              ],
            },
            'turnComplete': true,
          },
        });
        await _pumpEvents();

        // Inject fault: odd cycles -> abrupt 1006 close; even cycles -> server GoAway
        if (cycle.isOdd) {
          await activeChannel.simulateAbnormalDrop(1006, 'Network handoff');
        } else {
          activeChannel.emitServerJson({
            'goAway': {'timeLeft': '5s'},
          });
        }

        // Wait for automatic exponential backoff reconnect to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await _pumpEvents();

        expect(controller.isConnected, isTrue, reason: 'Failed to recover on cycle $cycle');
        expect(controller.sessionId, 'sess-${cycle + 1}');

        // Verify the resumed connection sent the latest resumption handle in setup
        final latestSetup = jsonDecode(channels.last.sentMessages.first as String)
            as Map<String, dynamic>;
        expect(
          latestSetup['setup']['session_resumption']['handle'],
          handle,
        );
      }

      // Verify quantitative metrics after 5 chaos cycles (1 initial + 5 reconnects = 6 connects)
      final metrics = controller.connectionMetrics;
      expect(metrics.connectAttempts, 6);
      expect(metrics.connectSuccesses, 6);
      expect(metrics.handshakeSuccessRate, 1.0);
      expect(metrics.reconnectAttempts, 5);
      expect(metrics.reconnectSuccesses, 5);
      expect(metrics.recoverySuccessRate, 1.0);
      expect(metrics.resumedSessionsCount, 5);
      expect(metrics.ttfaLatenciesMs.length, 5);
      expect(controller.transcripts.length, 10); // 5 user + 5 model turns preserved

      final sloReport = metrics.evaluateSlo();
      expect(sloReport.isCompliant, isTrue);
      expect(sloReport.stabilityScore, 100.0);

      controller.dispose();
    });

    testWidgets('GeminiLiveSessionInfoSheet displays quantitative stability and latency metrics', (tester) async {
      final genAI = GoogleGenAI(apiKey: 'test-key');
      final controller = GeminiLiveSessionController(liveService: genAI.live);

      controller.connectionMetrics.recordConnectStart();
      controller.connectionMetrics.recordConnectSuccess(explicitLatencyMs: 240.0);
      controller.connectionMetrics.recordFirstModelAudio(explicitTtfaMs: 195.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveSessionInfoSheet(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Stability Score'), findsOneWidget);
      expect(find.text('100.0/100 (CSR: 100.0%)'), findsOneWidget);
      expect(find.text('Setup Latency'), findsOneWidget);
      expect(find.text('240 ms (p95: 240 ms)'), findsOneWidget);
      expect(find.text('TTFA Latency'), findsOneWidget);
      expect(find.text('195 ms (p95: 195 ms)'), findsOneWidget);

      controller.dispose();
    });
  });
}

class _ChaosFakeChannel implements WebSocketChannel {
  final StreamController<Object?> _incoming = StreamController<Object?>.broadcast();
  final List<Object?> sentMessages = [];
  late final _ChaosFakeSink _sink = _ChaosFakeSink(sentMessages, _incoming);

  int? _closeCode;
  String? _closeReason;

  @override
  Stream<Object?> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  void emitServerJson(Map<String, dynamic> json) {
    if (!_incoming.isClosed) {
      _incoming.add(jsonEncode(json));
    }
  }

  Future<void> simulateAbnormalDrop(int code, String reason) async {
    _closeCode = code;
    _closeReason = reason;
    await _incoming.close();
  }

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChaosFakeSink implements WebSocketSink {
  final List<Object?> sentMessages;
  final StreamController<Object?> _incoming;

  _ChaosFakeSink(this.sentMessages, this._incoming);

  @override
  void add(dynamic data) {
    sentMessages.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => Future.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  @override
  Future<void> get done => Future.value();
}

Future<void> _pumpEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
