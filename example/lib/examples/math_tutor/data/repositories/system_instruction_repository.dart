import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/default_system_instruction.dart';

/// Persists the user-customised system instruction in SharedPreferences.
class SystemInstructionRepository {
  static const _systemInstructionPrefKey =
      'gemini_live_math_tutor_system_instruction';

  /// Loads the saved instruction. Stale saved prompts that lack the
  /// "CRITICAL ANSWER RULE" are replaced by the current default.
  Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSi = prefs.getString(_systemInstructionPrefKey);
      if (savedSi != null && savedSi.trim().isNotEmpty) {
        if (savedSi.contains('CRITICAL ANSWER RULE')) {
          return savedSi;
        }
        await prefs.setString(
          _systemInstructionPrefKey,
          defaultMathTutorSystemInstruction,
        );
      }
    } catch (e) {
      debugPrint('Load math system instruction error: $e');
    }
    return defaultMathTutorSystemInstruction;
  }

  Future<void> save(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_systemInstructionPrefKey, text);
  }
}
