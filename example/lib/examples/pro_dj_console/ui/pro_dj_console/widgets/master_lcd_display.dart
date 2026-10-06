import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/duration_format.dart';

/// CDJ master LCD header: elapsed time, BPM, key, engine status, beat grid.
class MasterLcdDisplay extends StatelessWidget {
  final Duration elapsed;
  final int bpm;
  final Scale? selectedScale;
  final bool isConnected;
  final bool isPlaying;
  final double currentRmsL;

  const MasterLcdDisplay({
    super.key,
    required this.elapsed,
    required this.bpm,
    required this.selectedScale,
    required this.isConnected,
    required this.isPlaying,
    required this.currentRmsL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2638), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Elapsed Time Readout
              Row(
                children: [
                  const Text(
                    'TIME  ',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    formatDjDuration(elapsed),
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),

              // Real-time BPM display
              Row(
                children: [
                  const Text(
                    'BPM  ',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$bpm.0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              // Harmonic Key / Scale
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A273A),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: Color(0xFF00E5FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedScale != null ? selectedScale!.name : 'NO KEY',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Engine Connection Pill
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isConnected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'LYRIA REALTIME ONLINE' : 'STANDBY',
                    style: TextStyle(
                      color: isConnected
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Multi-wave Beat Grid Display
          SizedBox(
            height: 38,
            child: Row(
              children: List.generate(48, (index) {
                final heightFactor = isPlaying
                    ? 0.2 +
                          math
                                  .sin(
                                    (index + elapsed.inMilliseconds / 80) * 0.4,
                                  )
                                  .abs() *
                              0.7 *
                              currentRmsL
                    : 0.15;
                final isBeatMarker = index % 4 == 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    alignment: Alignment.center,
                    child: Container(
                      height: 36 * heightFactor.clamp(0.1, 1.0),
                      decoration: BoxDecoration(
                        color: isBeatMarker
                            ? const Color(0xFF00E5FF)
                            : (index % 2 == 0
                                  ? const Color(0xFF304FFE)
                                  : const Color(0xFF651FFF)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
