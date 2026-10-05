import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/models.dart';

/// A modal bottom sheet widget for selecting Gemini Live voice personas.
///
/// Pre-populates Google's official Gemini Live voice roster:
/// Puck, Charon, Kore, Fenrir, Aoede, Leda, Orus, Zephyr, etc.
///
/// Features:
/// - Distinct tone & character tag pill display (e.g., "Warm", "Deep", "Energetic")
/// - Selected checkmark indication
/// - Instant tap callback with selected voice name or [GeminiLiveVoice] enum
class GeminiLiveVoiceSelectorSheet extends StatelessWidget {
  /// The currently selected voice name.
  final String currentVoice;

  /// Callback when a new voice is selected by name.
  final ValueChanged<String> onVoiceSelected;

  /// Optional callback when a [GeminiLiveVoice] is selected.
  final ValueChanged<GeminiLiveVoice>? onLiveVoiceSelected;

  /// Optional custom list of voices. If null, uses [defaultLiveVoices].
  final List<GeminiVoiceOption>? voices;

  /// Creates a voice selector modal sheet highlighting [currentVoice].
  const GeminiLiveVoiceSelectorSheet({
    super.key,
    required this.currentVoice,
    required this.onVoiceSelected,
    this.onLiveVoiceSelected,
    this.voices,
  });

  /// The standard set of popular Gemini Live prebuilt voices.
  static const List<GeminiVoiceOption> defaultLiveVoices = [
    GeminiVoiceOption(name: 'Puck', tone: 'Engaging, playful, and lively', gender: 'Neutral / Expressive', liveVoice: GeminiLiveVoice.puck),
    GeminiVoiceOption(name: 'Charon', tone: 'Deep, calm, and resonant', gender: 'Male / Deep', liveVoice: GeminiLiveVoice.charon),
    GeminiVoiceOption(name: 'Kore', tone: 'Warm, soothing, and empathetic', gender: 'Female / Warm', liveVoice: GeminiLiveVoice.kore),
    GeminiVoiceOption(name: 'Fenrir', tone: 'Authoritative, clear, and confident', gender: 'Male / Strong', liveVoice: GeminiLiveVoice.fenrir),
    GeminiVoiceOption(name: 'Aoede', tone: 'Melodic, gentle, and thoughtful', gender: 'Female / Calm', liveVoice: GeminiLiveVoice.aoede),
    GeminiVoiceOption(name: 'Leda', tone: 'Bright, energetic, and articulate', gender: 'Female / Bright', liveVoice: GeminiLiveVoice.leda),
    GeminiVoiceOption(name: 'Orus', tone: 'Steady, direct, and composed', gender: 'Male / Neutral', liveVoice: GeminiLiveVoice.orus),
    GeminiVoiceOption(name: 'Zephyr', tone: 'Crisp, modern, and friendly', gender: 'Neutral / Crisp', liveVoice: GeminiLiveVoice.zephyr),
  ];

  /// Full catalog of all 30 prebuilt Gemini Live and TTS voices.
  static List<GeminiVoiceOption> get allLiveVoices =>
      GeminiLiveVoice.values.map(GeminiVoiceOption.fromLiveVoice).toList();

  /// Convenient helper to display this selector as a modal bottom sheet.
  static Future<String?> show(
    BuildContext context, {
    required String currentVoice,
    List<GeminiVoiceOption>? voices,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GeminiLiveVoiceSelectorSheet(
        currentVoice: currentVoice,
        voices: voices,
        onVoiceSelected: (selected) {
          Navigator.of(context).pop(selected);
        },
      ),
    );
  }

  /// Convenient helper to display this selector as a modal bottom sheet and return a strongly typed [GeminiLiveVoice].
  static Future<GeminiLiveVoice?> showLiveVoice(
    BuildContext context, {
    required GeminiLiveVoice currentVoice,
    List<GeminiVoiceOption>? voices,
  }) async {
    final selectedName = await show(
      context,
      currentVoice: currentVoice.voiceName,
      voices: voices,
    );
    return GeminiLiveVoice.fromName(selectedName);
  }

  @override
  Widget build(BuildContext context) {
    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }

    final isDark = brightness == Brightness.dark;
    final effectiveVoices = voices ?? defaultLiveVoices;

    final bgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Title
          Row(
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                color: primaryColor,
                size: 22.0,
              ),
              const SizedBox(width: 10.0),
              Text(
                'Gemini Live Voice Persona',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Voice list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: effectiveVoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6.0),
              itemBuilder: (context, index) {
                final option = effectiveVoices[index];
                final isSelected = option.name.toLowerCase() == currentVoice.toLowerCase();

                return InkWell(
                  onTap: () {
                    onVoiceSelected(option.name);
                    if (onLiveVoiceSelected != null) {
                      final voice = option.liveVoice ?? GeminiLiveVoice.fromName(option.name);
                      if (voice != null) {
                        onLiveVoiceSelected!(voice);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(14.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: isDark ? 0.16 : 0.10)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.6)
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                        width: isSelected ? 1.2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    option.name,
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Text(
                                      option.gender,
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                option.tone,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: primaryColor,
                            size: 20.0,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Description of a prebuilt Gemini Live voice.
class GeminiVoiceOption {
  /// The official name of the voice persona (e.g. "Puck", "Charon").
  final String name;

  /// The characteristic tonal style and persona description.
  final String tone;

  /// The perceived vocal pitch or gender profile.
  final String gender;

  /// Optional strongly typed [GeminiLiveVoice] enum.
  final GeminiLiveVoice? liveVoice;

  /// Creates a Gemini voice option persona configuration.
  const GeminiVoiceOption({
    required this.name,
    required this.tone,
    required this.gender,
    this.liveVoice,
  });

  /// Creates a [GeminiVoiceOption] from a [GeminiLiveVoice] enum.
  factory GeminiVoiceOption.fromLiveVoice(GeminiLiveVoice voice) =>
      GeminiVoiceOption(
        name: voice.voiceName,
        tone: voice.tone,
        gender: voice.gender,
        liveVoice: voice,
      );
}
