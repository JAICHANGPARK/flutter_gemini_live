import 'package:flutter/material.dart';

import '../view_models/dj_midi_box_view_model.dart';
import 'dj_audio_visualizer.dart';

/// FFT visualizer + the big play / pause transport button.
class DjBottomControls extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;

  const DjBottomControls({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
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
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 2),
          child: Center(
            child: GestureDetector(
              onTap: vm.togglePlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Sleek indigo purple circular button matching image
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4C2A85), Color(0xFF2A1550)],
                  ),
                  border: Border.all(
                    color: isPlaying
                        ? const Color(0xFFA855F7)
                        : Colors.white.withAlpha(40),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPlaying
                          ? const Color(0xFFA855F7).withAlpha(160)
                          : Colors.black54,
                      blurRadius: isPlaying ? 20 : 12,
                      spreadRadius: isPlaying ? 3 : 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
