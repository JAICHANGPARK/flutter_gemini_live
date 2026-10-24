import 'dart:async';

/// A stream transformer and imperative gate that throttles high-frequency
/// camera or screen-capture frame streams down to Gemini Live's recommended
/// 1–2 FPS rate (`maxFps`).
///
/// ### Usage with a Stream
/// ```dart
/// cameraByteStream
///     .transform(GeminiLiveFrameRateLimiter<Uint8List>(maxFps: 1.0))
///     .listen((jpegBytes) => controller.sendRealtimeVideo(jpegBytes));
/// ```
///
/// ### Usage inside an imperative callback (`CameraController.startImageStream`)
/// ```dart
/// final limiter = GeminiLiveFrameRateLimiter<void>(maxFps: 1.5);
/// cameraController.startImageStream((image) {
///   if (!limiter.shouldEmitNow()) return;
///   // Encode and send frame...
/// });
/// ```
class GeminiLiveFrameRateLimiter<T> extends StreamTransformerBase<T, T> {
  /// Minimum interval between emitted frames.
  final Duration minInterval;

  DateTime? _lastEmittedAt;

  /// Creates a frame rate limiter with a fixed [minInterval] between frames.
  GeminiLiveFrameRateLimiter.fromInterval({
    this.minInterval = const Duration(seconds: 1),
  }) : assert(minInterval > Duration.zero, 'minInterval must be positive.');

  /// Creates a frame rate limiter capped at [maxFps] frames per second.
  ///
  /// Gemini Live vision streaming performs best at `1.0` to `2.0` FPS.
  factory GeminiLiveFrameRateLimiter({double maxFps = 1.0}) {
    assert(maxFps > 0, 'maxFps must be greater than 0.');
    final micros = (1000000 / maxFps).round();
    return GeminiLiveFrameRateLimiter.fromInterval(
      minInterval: Duration(microseconds: micros > 0 ? micros : 1),
    );
  }

  /// Target frames per second derived from [minInterval].
  double get maxFps => 1000000.0 / minInterval.inMicroseconds;

  /// Returns `true` and updates the internal timestamp if at least [minInterval]
  /// has elapsed since the last allowed frame (or if this is the first frame).
  bool shouldEmitNow([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (_lastEmittedAt == null ||
        current.difference(_lastEmittedAt!) >= minInterval) {
      _lastEmittedAt = current;
      return true;
    }
    return false;
  }

  /// Resets the internal timer so the next frame is emitted immediately.
  void reset() {
    _lastEmittedAt = null;
  }

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    DateTime? lastTime;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (event) {
            final now = DateTime.now();
            if (lastTime == null || now.difference(lastTime!) >= minInterval) {
              lastTime = now;
              controller.add(event);
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }
}
