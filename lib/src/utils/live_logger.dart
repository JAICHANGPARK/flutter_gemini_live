import 'package:flutter/foundation.dart';

/// Severity levels for Gemini Live logging.
enum GeminiLiveLogLevel {
  /// Verbose network traffic (raw JSON payloads, media packets).
  traffic(0, '📦 TRAFFIC'),

  /// Informational connection and lifecycle events.
  info(1, 'ℹ️ INFO'),

  /// Warning messages (deprecations, fallbacks, parameter adjustments).
  warning(2, '⚠️ WARNING'),

  /// Error events and failed connections.
  error(3, '❌ ERROR'),

  /// Completely silent / disabled.
  none(4, 'SILENT');

  final int priority;
  final String label;
  const GeminiLiveLogLevel(this.priority, this.label);

  /// Whether this level is enabled given the [activeLevel].
  bool isEnabled(GeminiLiveLogLevel activeLevel) =>
      priority >= activeLevel.priority;
}

/// Custom predicate to decide whether a log event should be recorded.
typedef GeminiLiveLogFilter = bool Function(
  String message,
  GeminiLiveLogLevel level,
  String? tag,
);

/// Custom transformer to sanitize, redact, or reformat raw log message strings
/// (e.g. masking sensitive tokens or pretty-printing JSON).
typedef GeminiLiveLogSanitizer = String Function(String message);

/// Custom formatter for building the final formatted log line.
typedef GeminiLiveLogFormatter = String Function(
  String message,
  GeminiLiveLogLevel level,
  DateTime timestamp,
  String? tag,
);

/// Custom classifier that infers a [GeminiLiveLogLevel] from a raw log string.
typedef GeminiLiveLogLevelClassifier = GeminiLiveLogLevel Function(
  String message,
);

/// A single structured log record captured by [GeminiLiveLogController].
class GeminiLiveLogEntry {
  /// Timestamp when the log event was recorded.
  final DateTime timestamp;

  /// Severity level of the log entry.
  final GeminiLiveLogLevel level;

  /// Optional category or module tag (e.g. `'WS'`, `'AUDIO'`, `'VISION'`, `'APP'`).
  final String? tag;

  /// Raw or sanitized message text.
  final String message;

  /// Full formatted message including prefix, tag, and level label.
  final String formattedMessage;

  /// Optional structured metadata map attached to this log entry.
  final Map<String, Object?>? metadata;

  /// Creates an immutable [GeminiLiveLogEntry].
  const GeminiLiveLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.formattedMessage,
    this.tag,
    this.metadata,
  });

  /// Whether this entry represents an outgoing client WebSocket frame (`📤`).
  bool get isOutgoing =>
      message.startsWith('📤') || message.contains('LiveMusic ->');

  /// Whether this entry represents an incoming server WebSocket frame (`📥`).
  bool get isIncoming => message.startsWith('📥');

  /// Formats [timestamp] as `HH:mm:ss.SSS` for compact on-device inspection.
  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Reactive in-memory log buffer and customizable controller for inspecting
/// Gemini Live SDK and application logs directly inside a running Flutter app.
///
/// Works seamlessly with `GeminiLiveLogOverlay` (attachable to any widget,
/// `Stack`, or `Overlay`) and `GeminiLiveLogConsole`.
class GeminiLiveLogController extends ChangeNotifier {
  /// Shared singleton instance for quick global in-app logging.
  static final GeminiLiveLogController instance = GeminiLiveLogController();

  static final RegExp _base64DataPattern = RegExp(
    r'"data"\s*:\s*"([A-Za-z0-9+/=]{120,})"',
  );

  /// Maximum number of log entries retained in the ring buffer.
  final int maxEntries;

  /// Whether to automatically compact long base64 `data` blobs in WebSocket
  /// traffic logs so on-device UI rendering stays fast and readable.
  final bool compactBase64Payloads;

  /// Optional custom filter predicate. Return `false` to drop a log entry.
  final GeminiLiveLogFilter? customFilter;

  /// Optional custom sanitizer to mask secrets or transform message text
  /// before it is stored or displayed.
  final GeminiLiveLogSanitizer? sanitizer;

  /// Optional custom formatter for [GeminiLiveLogEntry.formattedMessage].
  final GeminiLiveLogFormatter? formatter;

  /// Optional custom classifier to map raw SDK strings to [GeminiLiveLogLevel].
  final GeminiLiveLogLevelClassifier? levelClassifier;

  /// Optional external listener invoked whenever a new [GeminiLiveLogEntry] is
  /// recorded (useful for forwarding to Crashlytics, Sentry, Talker, or file logs).
  final void Function(GeminiLiveLogEntry entry)? onEntryAdded;

  final List<GeminiLiveLogEntry> _entries = <GeminiLiveLogEntry>[];

  bool _isPaused = false;
  GeminiLiveLogLevel? _filterLevel;
  String? _filterTag;
  String _searchQuery = '';
  int _errorCount = 0;
  int _warningCount = 0;

  /// Creates a customizable [GeminiLiveLogController].
  GeminiLiveLogController({
    this.maxEntries = 500,
    this.compactBase64Payloads = true,
    this.customFilter,
    this.sanitizer,
    this.formatter,
    this.levelClassifier,
    this.onEntryAdded,
  }) : assert(maxEntries > 0, 'maxEntries must be greater than 0.');

  /// All buffered log entries in chronological order.
  List<GeminiLiveLogEntry> get entries =>
      List<GeminiLiveLogEntry>.unmodifiable(_entries);

  /// Distinct non-null tags currently present in [entries].
  List<String> get availableTags {
    final set = <String>{};
    for (final entry in _entries) {
      if (entry.tag != null && entry.tag!.isNotEmpty) {
        set.add(entry.tag!);
      }
    }
    return set.toList(growable: false);
  }

  /// Log entries matching the active [filterLevel], [filterTag], and [searchQuery].
  List<GeminiLiveLogEntry> get filteredEntries {
    final query = _searchQuery.trim().toLowerCase();
    return _entries.where((entry) {
      if (_filterLevel != null && !entry.level.isEnabled(_filterLevel!)) {
        return false;
      }
      if (_filterTag != null && entry.tag != _filterTag) {
        return false;
      }
      if (query.isNotEmpty &&
          !entry.message.toLowerCase().contains(query) &&
          !entry.level.label.toLowerCase().contains(query) &&
          !(entry.tag?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Whether live log capture is currently paused.
  bool get isPaused => _isPaused;

  /// Minimum severity filter (`null` shows all captured levels).
  GeminiLiveLogLevel? get filterLevel => _filterLevel;

  /// Active tag filter (`null` shows all tags).
  String? get filterTag => _filterTag;

  /// Active search keyword filter.
  String get searchQuery => _searchQuery;

  /// Total number of [GeminiLiveLogLevel.error] entries currently in the buffer.
  int get errorCount => _errorCount;

  /// Total number of [GeminiLiveLogLevel.warning] entries currently in the buffer.
  int get warningCount => _warningCount;

  /// Most recent log entry, if any.
  GeminiLiveLogEntry? get latestEntry =>
      _entries.isNotEmpty ? _entries.last : null;

  /// Pauses or resumes live log capture.
  void setPaused(bool value) {
    if (_isPaused == value) return;
    _isPaused = value;
    notifyListeners();
  }

  /// Toggles the [isPaused] state.
  void togglePaused() => setPaused(!_isPaused);

  /// Updates the minimum severity filter (`null` for all levels).
  void setFilterLevel(GeminiLiveLogLevel? level) {
    if (_filterLevel == level) return;
    _filterLevel = level;
    notifyListeners();
  }

  /// Updates the active tag filter (`null` for all tags).
  void setFilterTag(String? tag) {
    if (_filterTag == tag) return;
    _filterTag = tag;
    notifyListeners();
  }

  /// Updates the keyword search query.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Convenience helper to log a custom [GeminiLiveLogLevel.traffic] message.
  void traffic(
    String message, {
    String? tag,
    Map<String, Object?>? metadata,
  }) =>
      addLog(message, GeminiLiveLogLevel.traffic, tag: tag, metadata: metadata);

  /// Convenience helper to log a custom [GeminiLiveLogLevel.info] message.
  void info(
    String message, {
    String? tag,
    Map<String, Object?>? metadata,
  }) =>
      addLog(message, GeminiLiveLogLevel.info, tag: tag, metadata: metadata);

  /// Convenience helper to log a custom [GeminiLiveLogLevel.warning] message.
  void warning(
    String message, {
    String? tag,
    Map<String, Object?>? metadata,
  }) =>
      addLog(message, GeminiLiveLogLevel.warning, tag: tag, metadata: metadata);

  /// Convenience helper to log a custom [GeminiLiveLogLevel.error] message.
  void error(
    String message, {
    String? tag,
    Map<String, Object?>? metadata,
  }) =>
      addLog(message, GeminiLiveLogLevel.error, tag: tag, metadata: metadata);

  /// Adds a new log record to the ring buffer unless [isPaused] is `true` or
  /// [customFilter] returns `false`.
  void addLog(
    String message,
    GeminiLiveLogLevel level, {
    String? tag,
    DateTime? timestamp,
    Map<String, Object?>? metadata,
  }) {
    if (_isPaused || level == GeminiLiveLogLevel.none) return;
    if (customFilter != null && !customFilter!(message, level, tag)) {
      return;
    }

    String processed = compactBase64Payloads ? _compactBase64(message) : message;
    if (sanitizer != null) {
      processed = sanitizer!(processed);
    }

    final now = timestamp ?? DateTime.now();
    final tagPart = (tag != null && tag.isNotEmpty) ? '[$tag] ' : '';
    final formatted = formatter != null
        ? formatter!(processed, level, now, tag)
        : '[GeminiLive] $tagPart${level.label} $processed';

    final entry = GeminiLiveLogEntry(
      timestamp: now,
      level: level,
      tag: tag,
      message: processed,
      formattedMessage: formatted,
      metadata: metadata,
    );

    if (_entries.length >= maxEntries) {
      final removed = _entries.removeAt(0);
      if (removed.level == GeminiLiveLogLevel.error && _errorCount > 0) {
        _errorCount--;
      } else if (removed.level == GeminiLiveLogLevel.warning &&
          _warningCount > 0) {
        _warningCount--;
      }
    }

    _entries.add(entry);
    if (level == GeminiLiveLogLevel.error) {
      _errorCount++;
    } else if (level == GeminiLiveLogLevel.warning) {
      _warningCount++;
    }

    onEntryAdded?.call(entry);
    notifyListeners();
  }

  /// Clears all buffered log entries and resets counters.
  void clear() {
    _entries.clear();
    _errorCount = 0;
    _warningCount = 0;
    notifyListeners();
  }

  /// Exports all (or [onlyFiltered]) log entries as a newline-separated string
  /// suitable for copying to the clipboard or sharing a bug report.
  String exportText({bool onlyFiltered = false}) {
    final source = onlyFiltered ? filteredEntries : _entries;
    return source
        .map((e) {
          final tagPrefix = (e.tag != null && e.tag!.isNotEmpty)
              ? '[${e.tag}] '
              : '';
          return '[${e.timeString}] $tagPrefix${e.level.label} ${e.message}';
        })
        .join('\n');
  }

  /// Creates a [GeminiLiveLogger] that feeds entries into this controller.
  ///
  /// Set [alsoPrintToConsole] to `true` to also forward logs to `debugPrint`.
  GeminiLiveLogger toLogger({
    GeminiLiveLogLevel level = GeminiLiveLogLevel.traffic,
    String? defaultTag,
    bool alsoPrintToConsole = false,
  }) {
    return GeminiLiveLogger._fromController(
      controller: this,
      level: level,
      defaultTag: defaultTag,
      alsoPrintToConsole: alsoPrintToConsole,
      levelClassifier: levelClassifier,
    );
  }

  /// Returns a `void Function(String)` callback directly compatible with
  /// `GoogleGenAI(logger: ...)` and `LiveService(logger: ...)`.
  void Function(String) toCallback({
    GeminiLiveLogLevel level = GeminiLiveLogLevel.traffic,
    String? defaultTag,
    bool alsoPrintToConsole = false,
  }) {
    return toLogger(
      level: level,
      defaultTag: defaultTag,
      alsoPrintToConsole: alsoPrintToConsole,
    ).toCallback();
  }

  static String _compactBase64(String input) {
    if (!input.contains('"data"')) return input;
    return input.replaceAllMapped(_base64DataPattern, (match) {
      final b64 = match.group(1) ?? '';
      return '"data":"<base64 ${b64.length} chars>"';
    });
  }
}

/// A structured, configurable logging facility for the Gemini Live SDK.
///
/// Supports severity-based filtering ([GeminiLiveLogLevel]), custom filters,
/// sanitizers, formatters, level classifiers, custom output sinks, and in-app
/// UI log controllers ([GeminiLiveLogController]).
class GeminiLiveLogger {
  /// The minimum severity level required for a log message to be emitted.
  final GeminiLiveLogLevel level;

  /// Optional default tag attached to messages emitted by this logger.
  final String? defaultTag;

  /// Optional filter predicate to suppress specific messages.
  final GeminiLiveLogFilter? filter;

  /// Optional sanitizer to redact or transform messages before output.
  final GeminiLiveLogSanitizer? sanitizer;

  /// Optional custom string formatter.
  final GeminiLiveLogFormatter? formatter;

  /// Optional custom classifier for `toCallback()` string inference.
  final GeminiLiveLogLevelClassifier? levelClassifier;

  /// The output callback handler. Defaults to [debugPrint].
  final void Function(String formattedMessage, GeminiLiveLogLevel level)?
      output;

  final GeminiLiveLogController? _controller;
  final bool _alsoPrintToConsole;

  /// Creates a customizable [GeminiLiveLogger].
  const GeminiLiveLogger({
    this.level = GeminiLiveLogLevel.info,
    this.defaultTag,
    this.filter,
    this.sanitizer,
    this.formatter,
    this.levelClassifier,
    this.output,
  }) : _controller = null,
       _alsoPrintToConsole = false;

  const GeminiLiveLogger._fromController({
    required GeminiLiveLogController controller,
    required this.level,
    this.defaultTag,
    required bool alsoPrintToConsole,
    this.levelClassifier,
  }) : _controller = controller,
       _alsoPrintToConsole = alsoPrintToConsole,
       filter = null,
       sanitizer = null,
       formatter = null,
       output = null;

  /// Creates a [GeminiLiveLogger] wired to a [GeminiLiveLogController]
  /// (defaults to [GeminiLiveLogController.instance]) for in-app overlay debugging.
  factory GeminiLiveLogger.inApp({
    GeminiLiveLogController? controller,
    GeminiLiveLogLevel level = GeminiLiveLogLevel.traffic,
    String? defaultTag,
    bool alsoPrintToConsole = false,
  }) {
    return (controller ?? GeminiLiveLogController.instance).toLogger(
      level: level,
      defaultTag: defaultTag,
      alsoPrintToConsole: alsoPrintToConsole,
    );
  }

  /// A preconfigured verbose logger that prints all events including raw traffic.
  static const GeminiLiveLogger verbose = GeminiLiveLogger(
    level: GeminiLiveLogLevel.traffic,
  );

  /// A preconfigured logger that prints info, warnings, and errors.
  static const GeminiLiveLogger standard = GeminiLiveLogger(
    level: GeminiLiveLogLevel.info,
  );

  /// A preconfigured silent logger that suppresses all output.
  static const GeminiLiveLogger silent = GeminiLiveLogger(
    level: GeminiLiveLogLevel.none,
  );

  /// Logs a message at [GeminiLiveLogLevel.traffic] severity.
  void traffic(String message) => log(message, GeminiLiveLogLevel.traffic);

  /// Logs a message at [GeminiLiveLogLevel.info] severity.
  void info(String message) => log(message, GeminiLiveLogLevel.info);

  /// Logs a message at [GeminiLiveLogLevel.warning] severity.
  void warning(String message) => log(message, GeminiLiveLogLevel.warning);

  /// Logs a message at [GeminiLiveLogLevel.error] severity.
  void error(String message) => log(message, GeminiLiveLogLevel.error);

  /// Emits a log message if [msgLevel] meets the minimum [level] and passes [filter].
  void log(String message, GeminiLiveLogLevel msgLevel) {
    if (level == GeminiLiveLogLevel.none) return;
    if (!msgLevel.isEnabled(level)) return;

    if (_controller != null) {
      final prevCount = _controller.entries.length;
      final prevLatest = _controller.latestEntry;
      _controller.addLog(message, msgLevel, tag: defaultTag);
      final latest = _controller.latestEntry;
      if (_alsoPrintToConsole &&
          latest != null &&
          (_controller.entries.length != prevCount ||
              !identical(latest, prevLatest))) {
        debugPrint(latest.formattedMessage);
      }
      return;
    }

    if (filter != null && !filter!(message, msgLevel, defaultTag)) return;

    final sanitized = sanitizer != null ? sanitizer!(message) : message;
    final formatted = formatter != null
        ? formatter!(sanitized, msgLevel, DateTime.now(), defaultTag)
        : '[GeminiLive] ${msgLevel.label} $sanitized';

    if (output != null) {
      output!(formatted, msgLevel);
    } else {
      debugPrint(formatted);
    }
  }

  /// Infers a [GeminiLiveLogLevel] from a raw SDK log string using
  /// [levelClassifier] if provided, or the default emoji/keyword rules.
  GeminiLiveLogLevel classifyMessage(String message) {
    if (levelClassifier != null) {
      return levelClassifier!(message);
    }
    if (message.startsWith('📤') ||
        message.startsWith('📥') ||
        message.startsWith('LiveMusic ->')) {
      return GeminiLiveLogLevel.traffic;
    }
    if (message.startsWith('⚠️')) {
      return GeminiLiveLogLevel.warning;
    }
    if (message.startsWith('❌') ||
        message.startsWith('🔴') ||
        message.startsWith('🚨') ||
        message.contains('Failed')) {
      return GeminiLiveLogLevel.error;
    }
    return GeminiLiveLogLevel.info;
  }

  /// Converts this logger into a legacy `void Function(String)` callback
  /// compatible with low-level [GoogleGenAI.logger] and [LiveService.logger].
  void Function(String) toCallback() {
    return (String message) {
      log(message, classifyMessage(message));
    };
  }
}
