import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import 'dj_vu_meter.dart';
import 'rotary_knob.dart';
import 'stem_kill_button.dart';

/// DJM center mixer: EQ knobs, VU meters, stem kill switches, crossfader.
class DjmCenterMixer extends StatelessWidget {
  final MusicGenerationMode mode;
  final double temperature;
  final double brightness;
  final double density;
  final double guidance;
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
    required this.onMuteBassChanged,
    required this.onMuteDrumsChanged,
    required this.onOnlyBassAndDrumsChanged,
    required this.onCrossfaderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232A38), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mixer Top Silk Screen Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4-CH DIGITAL MIXER',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withAlpha(120),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mode.name,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Band Rotary Knobs + TRIM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RotaryKnob(
                label: 'TRIM (TEMP)',
                value: temperature,
                min: 0.0,
                max: 2.5,
                color: Colors.purpleAccent,
                onChanged: onTemperatureChanged,
              ),
              RotaryKnob(
                label: 'HI (BRIGHT)',
                value: brightness,
                min: 0.0,
                max: 1.0,
                color: Colors.blueAccent,
                onChanged: onBrightnessChanged,
              ),
              RotaryKnob(
                label: 'MID (DENSE)',
                value: density,
                min: 0.0,
                max: 1.0,
                color: Colors.orangeAccent,
                onChanged: onDensityChanged,
              ),
              RotaryKnob(
                label: 'LOW (GUIDE)',
                value: guidance,
                min: 1.0,
                max: 6.0,
                color: Colors.cyanAccent,
                onChanged: onGuidanceChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Stereo VU Meters + Stem Isolator Switches
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left VU Meter (CH 1)
              DjVuMeter(level: currentRmsL, channelLabel: 'CH 1'),
              const SizedBox(width: 14),

              // Stem Isolator / Kill Buttons
              Column(
                children: [
                  StemKillButton('BASS KILL', muteBass, onMuteBassChanged),
                  const SizedBox(height: 8),
                  StemKillButton('DRUM KILL', muteDrums, onMuteDrumsChanged),
                  const SizedBox(height: 8),
                  StemKillButton(
                    'ONLY BASS/DRUM',
                    onlyBassAndDrums,
                    onOnlyBassAndDrumsChanged,
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Right VU Meter (CH 2)
              DjVuMeter(level: currentRmsR, channelLabel: 'CH 2'),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Master Crossfader (A <---> B)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C3446)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CROSSFADER [A]',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'A: ${(1.0 - crossfader).toStringAsFixed(2)}  |  B: ${crossfader.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      '[B] CROSSFADER',
                      style: TextStyle(
                        color: Color(0xFFFF9100),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: const Color(0xFFFF9100),
                    inactiveTrackColor: const Color(0xFF00E5FF),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: crossfader,
                    min: 0.0,
                    max: 1.0,
                    onChanged: onCrossfaderChanged,
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
