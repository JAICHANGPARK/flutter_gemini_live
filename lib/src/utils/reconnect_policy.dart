import 'dart:math' as math;

/// Configuration policy for automatic session reconnection and resumption
/// when a Gemini Live WebSocket session receives a `GoAway` notice or closes unexpectedly.
class GeminiLiveReconnectPolicy {
  /// Maximum number of consecutive reconnection attempts before giving up.
  /// Defaults to `3`.
  final int maxAttempts;

  /// Initial delay before the first reconnection attempt.
  /// Defaults to 500 milliseconds.
  final Duration initialDelay;

  /// Maximum backoff delay cap between reconnection attempts.
  /// Defaults to 8 seconds.
  final Duration maxDelay;

  /// Exponential multiplier applied after each failed attempt.
  /// Defaults to `2.0`.
  final double backoffMultiplier;

  /// Whether to proactively reconnect using the latest session resumption handle
  /// when the server emits a `GoAway` message. Defaults to `true`.
  final bool reconnectOnGoAway;

  /// Whether to automatically reconnect when the WebSocket closes with a non-normal
  /// close code (i.e. closeCode != 1000). Defaults to `true`.
  final bool reconnectOnAbnormalClose;

  /// Creates an exponential backoff reconnection policy for Gemini Live sessions.
  const GeminiLiveReconnectPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 8),
    this.backoffMultiplier = 2.0,
    this.reconnectOnGoAway = true,
    this.reconnectOnAbnormalClose = true,
  }) : assert(maxAttempts >= 0, 'maxAttempts must be non-negative.'),
       assert(backoffMultiplier >= 1.0, 'backoffMultiplier must be >= 1.0.');

  /// Computes the backoff delay for the given 0-indexed [attempt].
  Duration delayForAttempt(int attempt) {
    final safeAttempt = attempt < 0 ? 0 : attempt;
    final scaledMs =
        initialDelay.inMilliseconds * math.pow(backoffMultiplier, safeAttempt);
    final clampedMs = scaledMs
        .round()
        .clamp(initialDelay.inMilliseconds, maxDelay.inMilliseconds);
    return Duration(milliseconds: clampedMs);
  }
}
