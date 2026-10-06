import 'package:flutter/material.dart';

import '../../../domain/models/hot_cue_pad_data.dart';

/// 8 RGB hot cue / sound bank performance pads.
class PerformancePadsSection extends StatelessWidget {
  final List<HotCuePadData> hotCuePads;
  final int activePadIndex;
  final ValueChanged<int> onPadTap;

  const PerformancePadsSection({
    super.key,
    required this.hotCuePads,
    required this.activePadIndex,
    required this.onPadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252D3C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOT CUE / SOUND BANK (8-PAD RUBBER PERFORMANCE)',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'RGB VELOCITY BACKLIT',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: hotCuePads.length,
            itemBuilder: (context, index) {
              final pad = hotCuePads[index];
              final isActive = activePadIndex == index;
              return InkWell(
                onTap: () => onPadTap(index),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isActive
                        ? pad.color.withAlpha(80)
                        : const Color(0xFF1C222E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? pad.color : pad.color.withAlpha(80),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: pad.color.withAlpha(140),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pad.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? Colors.white : pad.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${pad.bpm} BPM',
                        style: TextStyle(
                          color: isActive ? Colors.white70 : Colors.white38,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
