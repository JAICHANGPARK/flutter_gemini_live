import 'dart:math' as math;

import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/material.dart';

import '../../../domain/dj_mix_summary.dart';
import '../../../domain/models/midi_knob_data.dart';
import '../dj_midi_box_i18n.dart';
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
    final i18n = DjMidiBoxI18n.current;
    // Generate active mix prompt summary string
    final String mixSummary = buildMixSummary(
      knobs: widget.knobs,
      customPromptText: widget.customPromptText,
      customPromptWeight: widget.customPromptWeight,
    );

    // Compute stereo L/R levels from FFT bands for the hardware meter bridge
    double leftLevel = 0.0;
    double rightLevel = 0.0;
    if (widget.isPlaying && _fftValues.isNotEmpty) {
      for (var i = 0; i < 16; i++) {
        leftLevel += _fftValues[i];
        rightLevel += _fftValues[16 + i];
      }
      leftLevel = (leftLevel / 7.5).clamp(0.0, 1.0);
      rightLevel = (rightLevel / 7.5).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF080B11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isPlaying
              ? const Color(0xFF38BDF8).withAlpha(130)
              : const Color(0xFF263042),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
        ],
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
              Flexible(
                child: Text(
                  i18n.liveFftTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isPlaying
                        ? const Color(0xFFE2E8F0)
                        : Colors.white38,
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Active Blend Pills
              Expanded(
                child: Text(
                  '🎛️ $mixSummary',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Hardware Stereo L/R 16-Segment Peak LED VU Meter Bridge
          _StereoVuMeterBridge(
            label: i18n.masterBusLabel,
            leftLevel: leftLevel,
            rightLevel: rightLevel,
          ),
          const SizedBox(height: 6),

          // Custom Painter for FFT Bars & Waveform line
          SizedBox(
            height: 40,
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
            children: [
              Flexible(
                child: Text(
                  i18n.subBassAxis,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  i18n.lowMidAxis,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  i18n.midHighAxis,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  i18n.trebleAxis,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StereoVuMeterBridge extends StatelessWidget {
  final String label;
  final double leftLevel;
  final double rightLevel;

  const _StereoVuMeterBridge({
    required this.label,
    required this.leftLevel,
    required this.rightLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1119),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1E2636)),
      ),
      child: Column(
        children: [
          _buildChannelBar('L', leftLevel),
          const SizedBox(height: 3),
          _buildChannelBar('R', rightLevel),
        ],
      ),
    );
  }

  Widget _buildChannelBar(String ch, double level) {
    const segments = 18;
    final activeSegments = (level * segments).round();
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text(
            ch,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(segments, (i) {
              final isLit = i < activeSegments;
              final Color segColor;
              if (i >= 15) {
                segColor = const Color(0xFFEF4444); // Red Peak/Clip (+3..+6dB)
              } else if (i >= 11) {
                segColor = const Color(0xFFF59E0B); // Amber (0dB)
              } else {
                segColor = const Color(0xFF10B981); // Green (-24..-3dB)
              }
              return Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 0.8),
                  decoration: BoxDecoration(
                    color: isLit ? segColor : segColor.withAlpha(32),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: isLit
                        ? [
                            BoxShadow(
                              color: segColor.withAlpha(150),
                              blurRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
          decoration: BoxDecoration(
            color: level > 0.88
                ? const Color(0xFFEF4444)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'CLIP',
            style: TextStyle(
              color: level > 0.88 ? Colors.white : const Color(0xFF475569),
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
