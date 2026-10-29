import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../music_studio_i18n.dart';
import '../view_models/music_studio_view_model.dart';
import 'param_slider.dart';

/// BPM, scale, mode, sliders, mute chips and the "Apply" button.
class GenerationConfigSection extends StatelessWidget {
  const GenerationConfigSection({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final i18n = MusicStudioI18n.current;
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.generationParamsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // BPM Slider
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'BPM: ${viewModel.bpm}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: viewModel.bpm.toDouble(),
                    min: 60,
                    max: 200,
                    divisions: 140,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => viewModel.setBpm(val.round()),
                  ),
                ),
              ],
            ),

            // Scale Selector
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    i18n.scaleKeyLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButton<Scale?>(
                    value: viewModel.selectedScale,
                    dropdownColor: const Color(0xFF262C38),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Colors.white24),
                    items: [
                      DropdownMenuItem<Scale?>(
                        value: null,
                        child: Text(i18n.defaultFreeScale),
                      ),
                      ...Scale.values
                          .where((s) => s != Scale.SCALE_UNSPECIFIED)
                          .map(
                            (s) => DropdownMenuItem<Scale?>(
                              value: s,
                              child: Text(s.name.replaceAll('_', ' ')),
                            ),
                          ),
                    ],
                    onChanged: viewModel.setScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Selector
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    i18n.modeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<MusicGenerationMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: MusicGenerationMode.QUALITY,
                          label: Text(
                            i18n.modeQuality,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        ButtonSegment(
                          value: MusicGenerationMode.DIVERSITY,
                          label: Text(
                            i18n.modeDiversity,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        ButtonSegment(
                          value: MusicGenerationMode.VOCALIZATION,
                          label: Text(
                            i18n.modeVocal,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                      selected: {viewModel.mode},
                      onSelectionChanged: (val) => viewModel.setMode(val.first),
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: Colors.purple.shade700,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MG-Series Hardware Rotary Potentiometer Strip (COMP Yellow, HIGH/MID Green, AUX Cyan)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF11151D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0084D6), width: 1.4),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'STUDIO DSP ROTARY STRIP // 48kHz',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05070B),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFF283244)),
                        ),
                        child: Text(
                          '${viewModel.bpm} BPM',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _StudioRotaryPot(
                          label: 'COMP/VAR',
                          value: viewModel.temperature,
                          min: 0.0,
                          max: 3.0,
                          capColor: const Color(0xFFEAB308), // Yellow Cap
                          onChanged: viewModel.setTemperature,
                        ),
                      ),
                      Expanded(
                        child: _StudioRotaryPot(
                          label: 'HIGH 10kHz',
                          value: viewModel.brightness,
                          min: 0.0,
                          max: 1.0,
                          capColor: const Color(0xFF00C853), // Green EQ Cap
                          onChanged: viewModel.setBrightness,
                        ),
                      ),
                      Expanded(
                        child: _StudioRotaryPot(
                          label: 'MID 2.5kHz',
                          value: viewModel.density,
                          min: 0.0,
                          max: 1.0,
                          capColor: const Color(0xFF00C853), // Green EQ Cap
                          onChanged: viewModel.setDensity,
                        ),
                      ),
                      Expanded(
                        child: _StudioRotaryPot(
                          label: 'AUX/GUIDE',
                          value: viewModel.guidance,
                          min: 0.0,
                          max: 6.0,
                          capColor: const Color(0xFF00B0FF), // Cyan AUX Cap
                          onChanged: viewModel.setGuidance,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sliders: Temperature, Guidance, Density, Brightness
            ParamSlider(
              label: i18n.varianceTempLabel,
              value: viewModel.temperature,
              min: 0.0,
              max: 3.0,
              onChanged: viewModel.setTemperature,
            ),
            ParamSlider(
              label: i18n.guidancePromptLabel,
              value: viewModel.guidance,
              min: 0.0,
              max: 6.0,
              onChanged: viewModel.setGuidance,
            ),
            ParamSlider(
              label: i18n.densityLabel,
              value: viewModel.density,
              min: 0.0,
              max: 1.0,
              onChanged: viewModel.setDensity,
            ),
            ParamSlider(
              label: i18n.brightnessLabel,
              value: viewModel.brightness,
              min: 0.0,
              max: 1.0,
              onChanged: viewModel.setBrightness,
            ),
            const SizedBox(height: 8),

            // Stems & Mute Toggles
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: Text(i18n.muteBassChip),
                  selected: viewModel.muteBass,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: viewModel.setMuteBass,
                ),
                FilterChip(
                  label: Text(i18n.muteDrumsChip),
                  selected: viewModel.muteDrums,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: viewModel.setMuteDrums,
                ),
                FilterChip(
                  label: Text(i18n.onlyBassAndDrumsChip),
                  selected: viewModel.onlyBassAndDrums,
                  selectedColor: Colors.teal.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: viewModel.setOnlyBassAndDrums,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auto-reset context on BPM/Scale change (Google Lyria docs best practice)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: viewModel.autoResetOnTempoScaleChange,
              title: Text(
                i18n.autoResetTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                i18n.autoResetSubtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              activeThumbColor: Colors.purpleAccent,
              onChanged: viewModel.setAutoResetOnTempoScaleChange,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isConnected
                    ? viewModel.sendGenerationConfig
                    : null,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(i18n.applyConfigButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioRotaryPot extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color capColor;
  final ValueChanged<double> onChanged;

  const _StudioRotaryPot({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.capColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final norm = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return GestureDetector(
      onDoubleTap: () => onChanged(min + (max - min) * 0.5),
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 90.0;
        final next = (value + delta * (max - min)).clamp(min, max);
        onChanged(next);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 46,
            height: 44,
            child: CustomPaint(
              painter: _StudioPotPainter(norm: norm, capColor: capColor),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: capColor,
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioPotPainter extends CustomPainter {
  final double norm;
  final Color capColor;

  const _StudioPotPainter({required this.norm, required this.capColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final currentAngle = startAngle + totalSweep * norm;

    // 11 Radial White Calibration Ticks
    const tickCount = 11;
    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + totalSweep * t;
      final isMajor = i == 0 || i == 5 || i == tickCount - 1;
      final r1 = radius * (isMajor ? 0.72 : 0.78);
      final r2 = radius * 0.94;
      canvas.drawLine(
        Offset(
          center.dx + r1 * math.cos(angle),
          center.dy + r1 * math.sin(angle),
        ),
        Offset(
          center.dx + r2 * math.cos(angle),
          center.dy + r2 * math.sin(angle),
        ),
        Paint()
          ..color = t <= norm + 0.01
              ? capColor
              : (isMajor ? Colors.white : Colors.white54)
          ..strokeWidth = isMajor ? 1.4 : 0.9,
      );
    }

    // Dark Fluted Skirt
    final skirtR = radius * 0.64;
    canvas.drawCircle(
      center.translate(0, 1.5),
      skirtR,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(center, skirtR, Paint()..color = const Color(0xFF1A1E26));
    canvas.drawCircle(
      center,
      skirtR,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Colored Center Cap
    final capR = radius * 0.44;
    canvas.drawCircle(center, capR, Paint()..color = capColor);

    // White Pointer Line
    canvas.drawLine(
      Offset(
        center.dx + (capR * 0.15) * math.cos(currentAngle),
        center.dy + (capR * 0.15) * math.sin(currentAngle),
      ),
      Offset(
        center.dx + (skirtR * 0.90) * math.cos(currentAngle),
        center.dy + (skirtR * 0.90) * math.sin(currentAngle),
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StudioPotPainter oldDelegate) {
    return oldDelegate.norm != norm || oldDelegate.capColor != capColor;
  }
}
