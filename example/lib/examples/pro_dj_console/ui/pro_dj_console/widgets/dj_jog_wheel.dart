import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vinyl_grooves_painter.dart';

/// Animated DJ Jog Wheel
class DjJogWheel extends StatelessWidget {
  final AnimationController anim;
  final bool isPlaying;
  final Color deckColor;
  final double rms;
  final int bpm;
  final VoidCallback onTap;

  const DjJogWheel({
    super.key,
    required this.anim,
    required this.isPlaying,
    required this.deckColor,
    required this.rms,
    required this.bpm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final rotAngle = anim.value * 2 * math.pi;
          return Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F1218),
              border: Border.all(color: const Color(0xFF2B3344), width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(200),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                if (isPlaying)
                  BoxShadow(
                    color: deckColor.withAlpha(
                      (100 * rms).toInt().clamp(20, 150),
                    ),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Vinyl Grooves
                CustomPaint(
                  size: const Size(150, 150),
                  painter: VinylGroovesPainter(),
                ),

                // Center LCD Screen
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A0C10),
                    border: Border.all(color: deckColor, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Position Needle
                      Transform.rotate(
                        angle: rotAngle,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 3,
                            height: 14,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.redAccent,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPlaying ? Icons.album : Icons.pause,
                            size: 18,
                            color: deckColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$bpm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
