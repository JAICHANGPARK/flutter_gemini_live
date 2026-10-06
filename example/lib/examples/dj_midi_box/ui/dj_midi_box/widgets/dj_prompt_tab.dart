import 'package:flutter/material.dart';

import '../../../domain/dj_defaults.dart';
import '../view_models/dj_midi_box_view_model.dart';

/// "PROMPT" tab of the DJ console: custom prompt injection + style presets.
Widget buildDjPromptTab(BuildContext context, DjMidiBoxViewModel vm) {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        children: [
          const Icon(Icons.edit_note, color: Color(0xFFFBBF24), size: 16),
          const SizedBox(width: 6),
          const Text(
            'CUSTOM PROMPT INJECTION',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: vm.customPromptActive,
            activeTrackColor: const Color(0xFFA855F7),
            onChanged: vm.setCustomPromptActive,
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        vm.customPromptActive
            ? 'Active: Steering the music along with the 16 rotary knobs'
            : 'Disabled: Only rotary knobs are active',
        style: TextStyle(
          color: vm.customPromptActive
              ? const Color(0xFF34D399)
              : Colors.white38,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: vm.customPromptController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Enter real-time music style prompt...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF1E123D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFA855F7)),
          ),
        ),
        onChanged: (_) => vm.onCustomPromptTextChanged(),
      ),
      const SizedBox(height: 12),

      // Weight Slider
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Prompt Weight (Influence):',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            '${(vm.customPromptWeight * 100).round()}%',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: const Color(0xFFA855F7),
          inactiveTrackColor: Colors.white12,
          thumbColor: const Color(0xFFA855F7),
          trackHeight: 3,
        ),
        child: Slider(
          value: vm.customPromptWeight,
          min: 0.05,
          max: 1.0,
          onChanged: vm.setCustomPromptWeight,
        ),
      ),

      const SizedBox(height: 10),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA855F7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.send_rounded, size: 16),
        label: const Text(
          'APPLY PROMPT TO MIX',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        onPressed: vm.applyCustomPrompt,
      ),

      const SizedBox(height: 20),
      const Text(
        'QUICK STYLE PRESETS',
        style: TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final preset in djPromptPresets)
            ActionChip(
              backgroundColor: const Color(0xFF26184A),
              label: Text(
                preset.$1,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              onPressed: () => vm.applyPreset(preset.$2),
            ),
        ],
      ),
    ],
  );
}
