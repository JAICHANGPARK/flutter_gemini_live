import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../view_models/music_studio_view_model.dart';
import 'param_slider.dart';

/// BPM, scale, mode, sliders, mute chips and the "Apply" button.
class GenerationConfigSection extends StatelessWidget {
  const GenerationConfigSection({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Music Generation Parameters',
              style: TextStyle(
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
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Scale / Key:',
                    style: TextStyle(
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
                      const DropdownMenuItem<Scale?>(
                        value: null,
                        child: Text('Default / Free Scale'),
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
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Mode:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SegmentedButton<MusicGenerationMode>(
                    segments: const [
                      ButtonSegment(
                        value: MusicGenerationMode.QUALITY,
                        label: Text('Quality', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: MusicGenerationMode.DIVERSITY,
                        label: Text(
                          'Diversity',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      ButtonSegment(
                        value: MusicGenerationMode.VOCALIZATION,
                        label: Text('Vocal', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {viewModel.mode},
                    onSelectionChanged: (val) => viewModel.setMode(val.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.purple.shade700,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sliders: Temperature, Guidance, Density, Brightness
            ParamSlider(
              label: 'Variance (Temp)',
              value: viewModel.temperature,
              min: 0.0,
              max: 3.0,
              onChanged: viewModel.setTemperature,
            ),
            ParamSlider(
              label: 'Guidance (Prompt)',
              value: viewModel.guidance,
              min: 0.0,
              max: 6.0,
              onChanged: viewModel.setGuidance,
            ),
            ParamSlider(
              label: 'Density',
              value: viewModel.density,
              min: 0.0,
              max: 1.0,
              onChanged: viewModel.setDensity,
            ),
            ParamSlider(
              label: 'Brightness',
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
                  label: const Text('Mute Bass'),
                  selected: viewModel.muteBass,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: viewModel.setMuteBass,
                ),
                FilterChip(
                  label: const Text('Mute Drums'),
                  selected: viewModel.muteDrums,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: viewModel.setMuteDrums,
                ),
                FilterChip(
                  label: const Text('Only Bass & Drums'),
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
              title: const Text(
                'Auto-reset Context on BPM/Scale change',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Lyria docs: BPM/Scale changes require resetContext() for new tempo/key adoption.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
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
                label: const Text('Apply Generation Config'),
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
