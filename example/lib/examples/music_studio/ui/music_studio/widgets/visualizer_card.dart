import 'package:flutter/material.dart';

import '../view_models/music_studio_view_model.dart';

/// Real-time stream visualizer (24 animated bars).
class VisualizerCard extends StatelessWidget {
  const VisualizerCard({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.visualizerTick]),
      builder: (context, _) {
        final isPlaying = viewModel.isPlaying;
        final bars = viewModel.visualizerBars;
        return Card(
          color: const Color(0xFF181B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Real-time Stream Visualizer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? Colors.green.withAlpha(40)
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPlaying ? 'PCM 48kHz LIVE' : 'STREAM IDLE',
                        style: TextStyle(
                          color: isPlaying ? Colors.greenAccent : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(bars.length, (index) {
                      final heightRatio = bars[index].clamp(0.05, 1.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        width: 6,
                        height: 70 * heightRatio,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              HSVColor.fromAHSV(
                                1.0,
                                (index * 14.0) % 360,
                                0.8,
                                0.9,
                              ).toColor(),
                              Colors.purple.shade900,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
