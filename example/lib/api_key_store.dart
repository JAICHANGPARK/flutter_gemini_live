import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyStore {
  static const _key = 'gemini_api_key';
  static String _apiKey = '';

  static String get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey.trim().isNotEmpty;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_key) ?? '';
  }

  static Future<void> save(String value) async {
    final trimmed = value.trim();
    final prefs = await SharedPreferences.getInstance();
    _apiKey = trimmed;

    if (trimmed.isEmpty) {
      await prefs.remove(_key);
      return;
    }

    await prefs.setString(_key, trimmed);
  }

  static String get maskedApiKey {
    if (!hasApiKey) return 'Not configured';
    if (_apiKey.length <= 8) return _apiKey;
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }
}
