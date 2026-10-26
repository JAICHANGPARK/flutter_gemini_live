import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../pro_dj_console_i18n.dart';
import 'dj_vu_meter.dart';
import 'rotary_knob.dart';
import 'stem_kill_button.dart';

/// DJM center mixer: EQ knobs, vertical channel faders, VU meters, stem kill switches, crossfader.
class DjmCenterMixer extends StatelessWidget {
  final MusicGenerationMode mode;
  final double temperature;
  final double brightness;
  final double density;
  final double guidance;
  final double deckAWeight;
  final double deckBWeight;
  final double currentRmsL;
  final double currentRmsR;
  final bool muteBass;
  final bool muteDrums;
  final bool onlyBassAndDrums;
  final double crossfader;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onDensityChanged;
  final ValueChanged<double> onGuidanceChanged;
  final ValueChanged<double> onDeckAWeightChanged;
  final ValueChanged<double> onDeckBWeightChanged;
  final ValueChanged<bool> onMuteBassChanged;
  final ValueChanged<bool> onMuteDrumsChanged;
  final ValueChanged<bool> onOnlyBassAndDrumsChanged;
  final ValueChanged<double> onCrossfaderChanged;

  const DjmCenterMixer({
    super.key,
    required this.mode,
    required this.temperature,
    required this.brightness,
    required this.density,
    required this.guidance,
    required this.deckAWeight,
    required this.deckBWeight,
    required this.currentRmsL,
    required this.currentRmsR,
    required this.muteBass,
    required this.muteDrums,
    required this.onlyBassAndDrums,
    required this.crossfader,
    required this.onTemperatureChanged,
    required this.onBrightnessChanged,
    required this.onDensityChanged,
    required this.onGuidanceChanged,
    required this.onDeckAWeightChanged,
    required this.onDeckBWeightChanged,
    required this.onMuteBassChanged,
    required this.onMuteDrumsChanged,
    required this.onOnlyBassAndDrumsChanged,
    required this.onCrossfaderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = ProDjConsoleI18n.current;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF161B26), Color(0xFF0E1219), Color(0xFF0A0D13)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283142), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mixer Top Silk Screen Brand + Corner Screws
          Row(
            children: [
              const _MixerScrew(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  i18n.mixerHeader,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withAlpha(120),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
                ),
                child: Text(
                  mode.name,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const _MixerScrew(),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFF232B3B)),
          const SizedBox(height: 10),

          // 4-Band Color-Coded Hardware Rotary Pots (GAIN White, COMP Yellow, EQ Green, AUX Cyan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: RotaryKnob(
                  label: i18n.knobTrimTemp,
                  value: temperature,
                  min: 0.0,
                  max: 2.5,
                  color: const Color(0xFFEAB308), // COMP Yellow/Gold
                  onChanged: onTemperatureChanged,
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: i18n.knobHiBright,
                  value: brightness,
                  min: 0.0,
                  max: 1.0,
                  color: const Color(0xFF00C853), // EQ HIGH Green
                  onChanged: onBrightnessChanged,
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: i18n.knobMidDense,
                  value: density,
                  min: 0.0,
                  max: 1.0,
                  color: const Color(0xFF00C853), // EQ MID Green
                  onChanged: onDensityChanged,
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: i18n.knobLowGuide,
                  value: guidance,
                  min: 1.0,
                  max: 6.0,
                  color: const Color(0xFF00B0FF), // AUX/FX Cyan-Blue
                  onChanged: onGuidanceChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // MG-Series Cyan-Blue Horizontal Ribbed Strip + Illuminated Amber CH ON Switches
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1728),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF0084D6), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AmberChannelOnButton(
                  label: 'CH 1 ON',
                  isOn: deckAWeight > 0.02,
                  onTap: () =>
                      onDeckAWeightChanged(deckAWeight > 0.02 ? 0.0 : 0.75),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Divider(height: 2, thickness: 1.2, color: Color(0xFF0084D6)),
                        SizedBox(height: 2),
                        Divider(height: 2, thickness: 1.2, color: Color(0xFF0084D6)),
                        SizedBox(height: 2),
                        Divider(height: 2, thickness: 1.2, color: Color(0xFF0084D6)),
                      ],
                    ),
                  ),
                ),
                _AmberChannelOnButton(
                  label: 'CH 2 ON',
                  isOn: deckBWeight > 0.02,
                  onTap: () =>
                      onDeckBWeightChanged(deckBWeight > 0.02 ? 0.0 : 0.75),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Hardware Channel Fader Bay: CH 1 Fader + CH 1 VU + Stem Isolator Kill Switches + CH 2 VU + CH 2 Fader
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0D14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1F2736)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // CH 1 Vertical Hardware Fader
                _VerticalChannelFader(
                  channelLabel: 'CH 1',
                  value: deckAWeight,
                  accentColor: const Color(0xFF00E5FF),
                  onChanged: onDeckAWeightChanged,
                ),
                const SizedBox(width: 6),

                // Left VU Meter (CH 1)
                DjVuMeter(level: currentRmsL, channelLabel: 'VU 1'),
                const SizedBox(width: 8),

                // Center Master Stem Isolator / Kill Switches
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ISOLATOR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StemKillButton(
                        i18n.bassKill,
                        muteBass,
                        onMuteBassChanged,
                      ),
                      const SizedBox(height: 6),
                      StemKillButton(
                        i18n.drumKill,
                        muteDrums,
                        onMuteDrumsChanged,
                      ),
                      const SizedBox(height: 6),
                      StemKillButton(
                        i18n.onlyBassDrum,
                        onlyBassAndDrums,
                        onOnlyBassAndDrumsChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right VU Meter (CH 2)
                DjVuMeter(level: currentRmsR, channelLabel: 'VU 2'),
                const SizedBox(width: 6),

                // CH 2 Vertical Hardware Fader
                _VerticalChannelFader(
                  channelLabel: 'CH 2',
                  value: deckBWeight,
                  accentColor: const Color(0xFFFF9100),
                  onChanged: onDeckBWeightChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Master Crossfader (A <---> B) with Silk-Screened Rail
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131822),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF283244)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        i18n.crossfaderLeft,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'A ${(1.0 - crossfader).toStringAsFixed(2)} | B ${crossfader.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        i18n.crossfaderRight,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFF9100),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Silk-screened crossfader calibration ticks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(11, (i) {
                    final isMajor = i == 0 || i == 5 || i == 10;
                    return Container(
                      width: isMajor ? 1.5 : 1.0,
                      height: isMajor ? 5.0 : 3.0,
                      color: isMajor ? Colors.white54 : Colors.white24,
                    );
                  }),
                ),
                SizedBox(
                  height: 26,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: const Color(0xFFFF9100),
                      inactiveTrackColor: const Color(0xFF00E5FF),
                      thumbShape: const _CrossfaderCapShape(),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: crossfader,
                      min: 0.0,
                      max: 1.0,
                      onChanged: onCrossfaderChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical Hardware Channel Fader with silk-screened dB scale (0..10) and grooved fader cap.
class _VerticalChannelFader extends StatelessWidget {
  final String channelLabel;
  final double value;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _VerticalChannelFader({
    required this.channelLabel,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channelLabel,
          style: TextStyle(
            color: accentColor,
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF141924),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            (clamped * 10).toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 96.0;
            onChanged((clamped + delta).clamp(0.0, 1.0));
          },
          onTapDown: (details) {
            final next = (1.0 - (details.localPosition.dy / 108.0)).clamp(
              0.0,
              1.0,
            );
            onChanged(next);
          },
          child: SizedBox(
            width: 34,
            height: 108,
            child: CustomPaint(
              painter: _VerticalFaderPainter(
                value: clamped,
                accentColor: accentColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalFaderPainter extends CustomPainter {
  final double value;
  final Color accentColor;

  const _VerticalFaderPainter({required this.value, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const topPad = 10.0;
    final bottomPad = size.height - 10.0;
    final trackHeight = bottomPad - topPad;

    // 1. Recessed Fader Slot Plate
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 0, size.width - 4, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(plateRect, Paint()..color = const Color(0xFF11151E));
    canvas.drawRRect(
      plateRect,
      Paint()
        ..color = const Color(0xFF232B3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. Silk-Screened Horizontal Graduation Marks (11 marks along the slot)
    for (var i = 0; i <= 10; i++) {
      final y = topPad + trackHeight * (i / 10.0);
      final isMajor = i == 0 || i == 2 || i == 5 || i == 10;
      final tickHalfW = isMajor ? 11.0 : 7.0;
      final tickPaint = Paint()
        ..color = isMajor ? Colors.white54 : Colors.white24
        ..strokeWidth = isMajor ? 1.3 : 0.9;
      canvas.drawLine(
        Offset(centerX - tickHalfW, y),
        Offset(centerX - 3, y),
        tickPaint,
      );
      canvas.drawLine(
        Offset(centerX + 3, y),
        Offset(centerX + tickHalfW, y),
        tickPaint,
      );
    }

    // 3. Center Dark Metal Fader Slot Track
    final slotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height / 2),
        width: 4,
        height: trackHeight + 4,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(slotRect, Paint()..color = const Color(0xFF05070B));

    // Active illuminated fader trail from bottom up to current fader position
    final capY = bottomPad - trackHeight * value;
    if (value > 0.01) {
      canvas.drawLine(
        Offset(centerX, bottomPad),
        Offset(centerX, capY),
        Paint()
          ..color = accentColor.withAlpha(190)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // 4. 3D Grooved Hardware Fader Cap
    final capRect = Rect.fromCenter(
      center: Offset(centerX, capY),
      width: 24,
      height: 14,
    );
    final capRRect = RRect.fromRectAndRadius(capRect, const Radius.circular(3));

    canvas.drawRRect(
      capRRect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black87,
    );

    canvas.drawRRect(
      capRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF475569), Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(capRect),
    );

    canvas.drawRRect(
      capRRect,
      Paint()
        ..color = accentColor.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Center white/colored fader reference line
    canvas.drawLine(
      Offset(capRect.left + 3, capY),
      Offset(capRect.right - 3, capY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _VerticalFaderPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.accentColor != accentColor;
  }
}

class _CrossfaderCapShape extends SliderComponentShape {
  const _CrossfaderCapShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(16, 22);

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
    final rect = Rect.fromCenter(center: center, width: 14, height: 20);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black87,
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF475569), Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawLine(
      Offset(center.dx, rect.top + 2),
      Offset(center.dx, rect.bottom - 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0,
    );
  }
}

class _MixerScrew extends StatelessWidget {
  const _MixerScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF334155),
        border: Border.all(color: const Color(0xFF0F172A), width: 1),
      ),
      child: Center(
        child: Container(width: 4, height: 1, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

class _AmberChannelOnButton extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  const _AmberChannelOnButton({
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isOn
                ? const [
                    Color(0xFFFFD54F),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                  ]
                : const [Color(0xFF383228), Color(0xFF221E18)],
          ),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isOn ? const Color(0xFFFFE082) : const Color(0xFF475569),
            width: 1.0,
          ),
          boxShadow: isOn
              ? const [
                  BoxShadow(
                    color: Color(0x99FFB300),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOn ? const Color(0xFF1E1300) : Colors.white54,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            fontSize: 8.0,
          ),
        ),
      ),
    );
  }
}
