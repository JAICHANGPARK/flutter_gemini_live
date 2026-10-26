import 'package:flutter/material.dart';

import '../dj_midi_box_i18n.dart';
import '../view_models/dj_midi_box_view_model.dart';
import 'dj_audio_visualizer.dart';

/// Hardware Master Output Bridge: Spectrum/VU Analyzer + Stem Kill Switches +
/// Master Drive Fader + Illuminated Hardware Transport Pad.
class DjBottomControls extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;

  const DjBottomControls({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = DjMidiBoxI18n.current;
    final isPlaying = vm.isPlaying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DjAudioVisualizer(
          audioPlayer: vm.audioPlayer,
          isPlaying: isPlaying,
          knobs: vm.knobs,
          customPromptText: vm.customPromptActive
              ? vm.customPromptController.text
              : null,
          customPromptWeight: vm.customPromptActive
              ? vm.customPromptWeight
              : null,
        ),

        // Hardware Master Transport & Fader Bay
        Container(
          margin: const EdgeInsets.fromLTRB(12, 2, 12, 10),
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A202C), Color(0xFF0E121A)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2B3548), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Hardware Stem Kill Buttons (BASS CUT / DRUM CUT)
              Flexible(
                flex: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: _HardwareKillPad(
                        label: i18n.bassCutLabel,
                        isKilled: vm.muteBass,
                        onTap: () => vm.setMuteBass(!vm.muteBass),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _HardwareKillPad(
                        label: i18n.drumCutLabel,
                        isKilled: vm.muteDrums,
                        onTap: () => vm.setMuteDrums(!vm.muteDrums),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 2. Horizontal Hardware Master Drive / Guidance Fader Rail
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090C12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF202838)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              i18n.masterGainLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${vm.guidance.toStringAsFixed(1)} dB',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontFamily: 'monospace',
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 22,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            activeTrackColor: const Color(0xFF38BDF8),
                            inactiveTrackColor: const Color(0xFF1E293B),
                            thumbShape: const _HardwareFaderCapShape(),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: vm.guidance.clamp(1.0, 6.0),
                            min: 1.0,
                            max: 6.0,
                            onChanged: vm.setGuidance,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Tactile Studio Backlit PLAY / CUE Hardware Button
              GestureDetector(
                onTap: vm.togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 64,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPlaying
                          ? const [Color(0xFF065F46), Color(0xFF042F2E)]
                          : const [Color(0xFF242C3D), Color(0xFF151A24)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlaying
                          ? const Color(0xFF10B981)
                          : const Color(0xFF475569),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPlaying
                            ? const Color(0xFF10B981).withAlpha(110)
                            : Colors.black87,
                        blurRadius: isPlaying ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? const Color(0xFF34D399)
                              : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: isPlaying
                              ? const [
                                  BoxShadow(
                                    color: Color(0xFF34D399),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HardwareKillPad extends StatelessWidget {
  final String label;
  final bool isKilled;
  final VoidCallback onTap;

  const _HardwareKillPad({
    required this.label,
    required this.isKilled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isKilled ? const Color(0xFF3B0D11) : const Color(0xFF121620),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isKilled ? const Color(0xFFEF4444) : const Color(0xFF283244),
            width: 1.2,
          ),
          boxShadow: isKilled
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(90),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 2.5,
              decoration: BoxDecoration(
                color: isKilled
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isKilled ? Colors.redAccent.shade100 : Colors.white70,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareFaderCapShape extends SliderComponentShape {
  const _HardwareFaderCapShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(14, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: 12, height: 18);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));

    // Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black87,
    );

    // Metallic fader cap body
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF475569), Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(rect),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Center white indicator line on fader cap
    canvas.drawLine(
      Offset(center.dx, rect.top + 2),
      Offset(center.dx, rect.bottom - 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8,
    );
  }
}
