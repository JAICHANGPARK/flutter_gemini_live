import 'dart:math' as math;

import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/material.dart';

import '../../../domain/dj_mix_summary.dart';
import '../../../domain/models/midi_knob_data.dart';
import 'dj_visualizer_painter.dart';

// ============================================================================
// Real-Time DJ FFT Spectrum & Waveform Visualizer
// ============================================================================

class DjAudioVisualizer extends StatefulWidget {
  final SoloudLiveAudioPlayer audioPlayer;
  final bool isPlaying;
  final List<MidiKnobData> knobs;
  final String? customPromptText;
  final double? customPromptWeight;

  const DjAudioVisualizer({
    super.key,
    required this.audioPlayer,
    required this.isPlaying,
    required this.knobs,
    this.customPromptText,
    this.customPromptWeight,
  });

  @override
  State<DjAudioVisualizer> createState() => _DjAudioVisualizerState();
}

class _DjAudioVisualizerState extends State<DjAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  List<double> _fftValues = List.filled(32, 0.0);
  List<double> _peakCaps = List.filled(32, 0.0);
  List<double> _waveform = List.filled(64, 0.0);

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    if (widget.isPlaying) {
      _ticker.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DjAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _ticker.repeat();
      } else {
        _ticker.stop();
        setState(() {
          _fftValues = List.filled(32, 0.0);
          _peakCaps = List.filled(32, 0.0);
          _waveform = List.filled(64, 0.0);
        });
      }
    }
  }

  void _onTick() {
    if (!widget.isPlaying) return;
    final rawFft = widget.audioPlayer.getLiveFft(count: 32);
    final rawWave = widget.audioPlayer.getLiveWaveform(count: 64);

    final newPeaks = List<double>.from(_peakCaps);
    for (var i = 0; i < 32; i++) {
      final current = rawFft[i];
      if (current >= newPeaks[i]) {
        newPeaks[i] = current;
      } else {
        newPeaks[i] = math.max(0.0, newPeaks[i] - 0.035);
      }
    }

    setState(() {
      _fftValues = rawFft;
      _peakCaps = newPeaks;
      _waveform = rawWave;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate active mix prompt summary string
    final String mixSummary = buildMixSummary(
      knobs: widget.knobs,
      customPromptText: widget.customPromptText,
      customPromptWeight: widget.customPromptWeight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF140D2B).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isPlaying
              ? const Color(0xFFA855F7).withAlpha(140)
              : Colors.white12,
          width: 1.5,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withAlpha(45),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info row: live status + active blend
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isPlaying
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                  boxShadow: widget.isPlaying
                      ? [
                          const BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE FFT & WAVEFORM',
                style: TextStyle(
                  color: widget.isPlaying ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Active Blend Pills
              Flexible(
                child: Text(
                  '🎛️ $mixSummary',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Custom Painter for FFT Bars & Waveform line
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: DjVisualizerPainter(
                fftValues: _fftValues,
                peakCaps: _peakCaps,
                waveform: _waveform,
                isPlaying: widget.isPlaying,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Frequency axis indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SUB BASS (40Hz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LOW-MID (500Hz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'MID-HIGH (4kHz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TREBLE (16kHz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
