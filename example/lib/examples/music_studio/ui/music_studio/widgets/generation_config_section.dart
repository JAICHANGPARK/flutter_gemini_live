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
