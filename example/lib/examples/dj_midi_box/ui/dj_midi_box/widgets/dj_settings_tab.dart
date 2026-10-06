import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/dj_defaults.dart';
import '../view_models/dj_midi_box_view_model.dart';

/// "SETTINGS" tab of the DJ console: tempo, mode, scale and mix sliders.
Widget buildDjSettingsTab(BuildContext context, DjMidiBoxViewModel vm) {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // BPM
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TEMPO (BPM)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            '${vm.bpm} BPM',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: const Color(0xFF38BDF8),
          inactiveTrackColor: Colors.white12,
          thumbColor: const Color(0xFF38BDF8),
          trackHeight: 3,
        ),
        child: Slider(
          value: vm.bpm.toDouble(),
          min: 60,
          max: 180,
          divisions: 120,
          onChanged: vm.setBpmFromSlider,
        ),
      ),
      Wrap(
        spacing: 6,
        children: djBpmPresets.map((b) {
          final isSel = vm.bpm == b;
          return ChoiceChip(
            selected: isSel,
            selectedColor: const Color(0xFF38BDF8).withAlpha(60),
            backgroundColor: const Color(0xFF1E123D),
            label: Text(
              '$b',
              style: TextStyle(
                color: isSel ? const Color(0xFF38BDF8) : Colors.white70,
                fontSize: 10,
              ),
            ),
            onSelected: (_) => vm.setBpmPreset(b),
          );
        }).toList(),
      ),

      const SizedBox(height: 18),
      const Divider(color: Colors.white12),
      const SizedBox(height: 8),

      // Generation Mode
      const Text(
        'GENERATION MODE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E123D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MusicGenerationMode>(
            value: vm.mode,
            dropdownColor: const Color(0xFF1E123D),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: MusicGenerationMode.values
                .where(
                  (m) =>
                      m !=
                      MusicGenerationMode.MUSIC_GENERATION_MODE_UNSPECIFIED,
                )
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (m) {
              if (m != null) {
                vm.setMode(m);
              }
            },
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Scale
      const Text(
        'MUSICAL SCALE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E123D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Scale?>(
            value: vm.selectedScale,
            dropdownColor: const Color(0xFF1E123D),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Auto Scale (Model Decides)'),
              ),
              ...Scale.values
                  .where((s) => s != Scale.SCALE_UNSPECIFIED)
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name.replaceAll('_', ' ')),
                    ),
                  ),
            ],
            onChanged: vm.setScale,
          ),
        ),
      ),

      const SizedBox(height: 16),
      const Divider(color: Colors.white12),
      const SizedBox(height: 8),

      // Guidance Slider
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'GUIDANCE SCALE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            vm.guidance.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      Slider(
        value: vm.guidance,
        min: 1.0,
        max: 6.0,
        activeColor: const Color(0xFFFBBF24),
        onChanged: vm.setGuidance,
      ),

      // Density Slider
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'SOUND DENSITY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            '${(vm.density * 100).round()}%',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      Slider(
        value: vm.density,
        min: 0.0,
        max: 1.0,
        activeColor: const Color(0xFF34D399),
        onChanged: vm.setDensity,
      ),

      // Brightness Slider
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'BRIGHTNESS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            '${(vm.brightness * 100).round()}%',
            style: const TextStyle(
              color: Color(0xFFEC4899),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      Slider(
        value: vm.brightness,
        min: 0.0,
        max: 1.0,
        activeColor: const Color(0xFFEC4899),
        onChanged: vm.setBrightness,
      ),

      const SizedBox(height: 12),
      // Mute bass & drums
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Mute Bass',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        value: vm.muteBass,
        activeTrackColor: const Color(0xFFEF4444),
        onChanged: vm.setMuteBass,
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Mute Drums',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        value: vm.muteDrums,
        activeTrackColor: const Color(0xFFEF4444),
        onChanged: vm.setMuteDrums,
      ),
    ],
  );
}
