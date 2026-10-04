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
  bool isEnabled(GeminiLiveLogLevel activeLevel) => priority >= activeLevel.priority;
}

/// A structured, configurable logging facility for the Gemini Live SDK.
///
/// Supports severity-based filtering ([GeminiLiveLogLevel]), custom output sinks,
/// and convenient default configurations.
class GeminiLiveLogger {
  /// The minimum severity level required for a log message to be emitted.
  final GeminiLiveLogLevel level;

  /// The output callback handler. Defaults to [debugPrint].
  final void Function(String formattedMessage, GeminiLiveLogLevel level)? output;

  /// Creates a [GeminiLiveLogger] with optional level and output handler.
  const GeminiLiveLogger({
    this.level = GeminiLiveLogLevel.info,
    this.output,
  });

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

  /// Emits a log message if [msgLevel] meets the minimum [level].
  void log(String message, GeminiLiveLogLevel msgLevel) {
    if (level == GeminiLiveLogLevel.none) return;
    if (!msgLevel.isEnabled(level)) return;

    final formatted = '[GeminiLive] ${msgLevel.label} $message';
    if (output != null) {
      output!(formatted, msgLevel);
    } else {
      debugPrint(formatted);
    }
  }

  /// Converts this logger into a legacy `void Function(String)` callback
  /// compatible with low-level [GoogleGenAI.logger] and [LiveService.logger].
  void Function(String) toCallback() {
    return (String message) {
      // Intelligently infer log level from message prefix if present
      if (message.startsWith('📤') || message.startsWith('📥')) {
        traffic(message);
      } else if (message.startsWith('⚠️')) {
        warning(message);
      } else if (message.startsWith('❌') || message.contains('Failed')) {
        error(message);
      } else {
        info(message);
      }
    };
  }
}
