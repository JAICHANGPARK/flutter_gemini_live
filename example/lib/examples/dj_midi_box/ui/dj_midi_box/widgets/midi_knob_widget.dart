import 'package:flutter/material.dart';

import '../../../domain/models/midi_knob_data.dart';
import 'midi_knob_painter.dart';

// ============================================================================
// Hardware Audio Mixer Channel Strip Module (Rotary Potentiometer + Pad)
// ============================================================================

class MidiKnobWidget extends StatelessWidget {
  final int channelNumber;
  final MidiKnobData data;
  final double rmsLevel;
  final ValueChanged<double> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MidiKnobWidget({
    super.key,
    required this.channelNumber,
    required this.data,
    required this.rmsLevel,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatDb(double weight) {
    if (weight <= 0.02) return '-∞ dB';
    // Map 0.02..1.0 -> -24.0 dB .. +6.0 dB (unity 0.0 dB around 0.80)
    final db = (weight - 0.80) * 30.0;
    final sign = db >= 0 ? '+' : '';
    return '$sign${db.toStringAsFixed(1)}dB';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = data.weight > 0.02;
    final chText = 'CH ${channelNumber.toString().padLeft(2, '0')}';
    final dbText = _formatDb(data.weight);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 80.0;
        final nextWeight = (data.weight + delta).clamp(0.0, 1.0);
        onChanged(nextWeight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A202C), // Brushed dark slate top
              Color(0xFF12161F), // Recessed lower bay
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? data.color.withAlpha(150)
                : const Color(0xFF283040),
            width: isActive ? 1.4 : 1.0,
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
            if (isActive)
              BoxShadow(
                color: data.color.withAlpha(35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Hardware Channel Strip Silk-Screen + SIG/PEAK LED + dB Readout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    chText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 8.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? (data.weight > 0.9
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981))
                              : const Color(0xFF1E293B),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: data.weight > 0.9
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          dbText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? data.color
                                : const Color(0xFF475569),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. Rotary Potentiometer Dial with Silk-Screened Ticks
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CustomPaint(
                      painter: MidiKnobPainter(
                        weight: data.weight,
                        color: data.color,
                        isActive: isActive,
                        pulse: isActive ? rmsLevel : 0.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Tactile Backlit Hardware CUE / ON Pad Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0E131D)
                    : const Color(0xFF0A0D14),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isActive
                      ? data.color.withAlpha(180)
                      : const Color(0xFF1F2735),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thin Illuminated LED Strip on the Hardware Button
                  Container(
                    width: 22,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 2.5),
                    decoration: BoxDecoration(
                      color: isActive ? data.color : const Color(0xFF263042),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: data.color.withAlpha(190),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Text(
                    data.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
