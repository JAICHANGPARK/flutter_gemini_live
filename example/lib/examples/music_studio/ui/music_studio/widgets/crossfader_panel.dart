import 'package:flutter/material.dart';

import '../view_models/music_studio_view_model.dart';

/// Prompt DJ crossfader between prompt A and prompt B.
class CrossfaderPanel extends StatelessWidget {
  const CrossfaderPanel({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final crossfaderValue = viewModel.crossfaderValue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF222733),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: Colors.purpleAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Prompt DJ Crossfader (A ⟷ B)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                'A: ${(1.0 - crossfaderValue).toStringAsFixed(2)} · B: ${crossfaderValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Colors.purpleAccent,
              inactiveTrackColor: Colors.cyanAccent,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: crossfaderValue,
              min: 0.0,
              max: 1.0,
              onChanged: viewModel.applyCrossfader,
            ),
          ),
        ],
      ),
    );
  }
}
