import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/audio_utils.dart';

/// A reactive waveform audio visualizer widget for Gemini Live sessions.
///
/// Visualizes audio energy in real time using smooth, animated vertical bars.
/// Can be driven directly by [amplitude], an [amplitudeStream], or a raw
/// 16-bit linear PCM [audioStream] (e.g. from microphone input or incoming
/// model audio parts).
class GeminiLiveWaveform extends StatefulWidget {
  /// Normalized current audio amplitude between `0.0` and `1.0`.
  final double? amplitude;

  /// Stream of normalized audio amplitudes (0.0 to 1.0).
  final Stream<double>? amplitudeStream;

  /// Stream of raw 16-bit Linear PCM Little-Endian audio chunk bytes.
  final Stream<Uint8List>? audioStream;

  /// Number of vertical waveform bars. Defaults to 7.
  final int barCount;

  /// Total width of the visualizer. Defaults to 120.0.
  final double width;

  /// Total height of the visualizer. Defaults to 36.0.
  final double height;

  /// Width of each bar. Defaults to 4.0.
  final double barWidth;

  /// Spacing between bars. Defaults to 3.0.
  final double spacing;

  /// Minimum height of a bar when silent. Defaults to 4.0.
  final double minBarHeight;

  /// Color of the visualizer bars. Defaults to primary color of the theme.
  final Color? color;

  /// Optional gradient applied vertically across each bar.
  final Gradient? gradient;

  /// Corner radius of the bars. If null, automatically uses pill capsule radius (`barWidth / 2`).
  final double? borderRadius;

  /// Whether bars gently breathe with subtle organic motion when audio is silent.
  /// Defaults to `true` for a natural, native audio hardware aesthetic.
  final bool enableIdleBreathing;

  /// Creates a reactive waveform audio visualizer widget.
  const GeminiLiveWaveform({
    super.key,
    this.amplitude,
    this.amplitudeStream,
    this.audioStream,
    this.barCount = 7,
    this.width = 120.0,
    this.height = 36.0,
    this.barWidth = 4.0,
    this.spacing = 3.0,
    this.minBarHeight = 4.0,
    this.color,
    this.gradient,
    this.borderRadius,
    this.enableIdleBreathing = true,
  });

  @override
  State<GeminiLiveWaveform> createState() => _GeminiLiveWaveformState();
}

class _GeminiLiveWaveformState extends State<GeminiLiveWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  StreamSubscription<double>? _amplitudeSubscription;
  StreamSubscription<Uint8List>? _audioSubscription;

  double _currentAmplitude = 0.0;
  double _targetAmplitude = 0.0;
  final List<double> _barWeights = [];

  @override
  void initState() {
    super.initState();
    _initWeights();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _ticker.repeat();

    _subscribeStreams();
    if (widget.amplitude != null) {
      _targetAmplitude = widget.amplitude!.clamp(0.0, 1.0);
    }
  }

  void _initWeights() {
    _barWeights.clear();
    final half = widget.barCount / 2.0;
    for (int i = 0; i < widget.barCount; i++) {
      // Bell-shaped distribution around the center bars
      final dist = (i + 0.5 - half).abs() / half;
      final weight = (1.0 - 0.45 * dist).clamp(0.2, 1.0);
      _barWeights.add(weight);
    }
  }

  void _subscribeStreams() {
    _amplitudeSubscription?.cancel();
    _audioSubscription?.cancel();

    if (widget.amplitudeStream != null) {
      _amplitudeSubscription = widget.amplitudeStream!.listen((amp) {
        if (mounted) {
          setState(() {
            _targetAmplitude = GeminiLiveAudioUtils.toVisualScale(amp);
          });
        }
      });
    } else if (widget.audioStream != null) {
      _audioSubscription = widget.audioStream!.listen((chunk) {
        final rms = GeminiLiveAudioUtils.calculateRms(chunk);
        if (mounted) {
          setState(() {
            _targetAmplitude = GeminiLiveAudioUtils.toVisualScale(rms);
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(GeminiLiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) {
      _initWeights();
    }
    if (widget.amplitude != oldWidget.amplitude && widget.amplitude != null) {
      _targetAmplitude = GeminiLiveAudioUtils.toVisualScale(widget.amplitude!);
    }
    if (widget.amplitudeStream != oldWidget.amplitudeStream ||
        widget.audioStream != oldWidget.audioStream) {
      _subscribeStreams();
    }
  }

  void _onTick() {
    if (!mounted) return;
    // Smooth exponential decay/rise towards target amplitude
    final double diff = _targetAmplitude - _currentAmplitude;
    final double step = diff > 0 ? 0.35 : 0.15;
    if (diff.abs() > 0.002) {
      setState(() {
        _currentAmplitude += diff * step;
      });
    } else if (_targetAmplitude > 0) {
      // Slowly decay target when idle
      _targetAmplitude = math.max(0.0, _targetAmplitude - 0.02);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _amplitudeSubscription?.cancel();
    _audioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color? themePrimary;
    try {
      themePrimary = Theme.of(context).colorScheme.primary;
    } catch (_) {
      try {
        themePrimary = CupertinoTheme.of(context).primaryColor;
      } catch (_) {
        themePrimary = const Color(0xFF007AFF);
      }
    }

    final effectiveColor = widget.color ?? themePrimary;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitude: _currentAmplitude,
          weights: _barWeights,
          barCount: widget.barCount,
          barWidth: widget.barWidth,
          spacing: widget.spacing,
          minBarHeight: widget.minBarHeight,
          color: effectiveColor,
          gradient: widget.gradient,
          borderRadius: widget.borderRadius ?? (widget.barWidth / 2.0),
          phase: widget.enableIdleBreathing ? _ticker.value * 2 * math.pi : 0.0,
          enableIdleBreathing: widget.enableIdleBreathing,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double amplitude;
  final List<double> weights;
  final int barCount;
  final double barWidth;
  final double spacing;
  final double minBarHeight;
  final Color color;
  final Gradient? gradient;
  final double borderRadius;
  final double phase;
  final bool enableIdleBreathing;

  _WaveformPainter({
    required this.amplitude,
    required this.weights,
    required this.barCount,
    required this.barWidth,
    required this.spacing,
    required this.minBarHeight,
    required this.color,
    this.gradient,
    required this.borderRadius,
    this.phase = 0.0,
    this.enableIdleBreathing = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barCount <= 0) return;

    final totalBarsWidth = (barCount * barWidth) + ((barCount - 1) * spacing);
    final startX = (size.width - totalBarsWidth) / 2.0;
    final centerY = size.height / 2.0;
    final maxAvailableHeight = size.height;

    final paint = Paint()..color = color;

    for (int i = 0; i < barCount; i++) {
      final weight = i < weights.length ? weights[i] : 1.0;

      // Subtle organic breathing motion when amplitude is idle
      double idleOffset = 0.0;
      if (enableIdleBreathing && amplitude < 0.08) {
        final idleWeight = (1.0 - amplitude / 0.08).clamp(0.0, 1.0);
        idleOffset = math.sin(phase + (i * 0.7)) * 0.08 * idleWeight;
      }

      final scaledAmp = (amplitude * weight + idleOffset).clamp(0.0, 1.0);
      final barHeight = (minBarHeight + (maxAvailableHeight - minBarHeight) * scaledAmp)
          .clamp(minBarHeight, maxAvailableHeight);

      final left = startX + i * (barWidth + spacing);
      final top = centerY - (barHeight / 2.0);
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      if (gradient != null) {
        paint.shader = gradient!.createShader(rect);
      }

      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.color != color ||
        oldDelegate.barCount != barCount ||
        oldDelegate.gradient != gradient ||
        oldDelegate.phase != phase;
  }
}
