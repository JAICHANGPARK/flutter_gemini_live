import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/math_solution_record.dart';

/// Persists the solved-problem history in SharedPreferences.
class SolutionHistoryRepository {
  static const _historyPrefKey = 'gemini_live_math_tutor_history';
  static const _maxRecords = 50;

  /// Returns the saved records, or `null` when nothing is stored (or loading
  /// failed) so callers can leave their current list untouched.
  Future<List<MathSolutionRecord>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => MathSolutionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Load math history error: $e');
    }
    return null;
  }

  Future<void> save(List<MathSolutionRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep up to 50 latest records to optimize storage
      final toSave = records.take(_maxRecords).map((r) => r.toJson()).toList();
      await prefs.setString(_historyPrefKey, jsonEncode(toSave));
    } catch (e) {
      debugPrint('Save math history error: $e');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyPrefKey);
  }
}
