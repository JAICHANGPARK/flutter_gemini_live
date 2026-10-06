import 'package:flutter/material.dart';

import '../view_models/dj_midi_box_view_model.dart';

/// Glowing audio-reactive orb + status line shown on the upright half of a
/// half-opened foldable (tabletop / flex mode).
class DjTabletopOrb extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;
  final Animation<double> pulse;

  const DjTabletopOrb({
    super.key,
    required this.viewModel,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final pulseScale =
                  1.0 + (vm.isPlaying ? vm.rmsLevel * 0.45 : 0.0);
              return Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA855F7).withValues(alpha: 0.6),
                        const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: vm.isPlaying
                          ? const Color(0xFFA855F7)
                          : Colors.white24,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      vm.isPlaying ? Icons.graphic_eq : Icons.music_note,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            vm.isPlaying
                ? 'PLAYING · ${vm.bpm} BPM'
                : 'READY · TAP DIALS TO PLAY',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
