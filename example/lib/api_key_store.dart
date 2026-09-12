import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyStore {
  static const _key = 'gemini_api_key';
  static const _modelKey = 'gemini_live_model';

  static const String defaultModel = 'gemini-3.1-flash-live-preview';
  static const List<String> availableModels = [
    'gemini-3.1-flash-live-preview',
    'gemini-2.5-flash-native-audio-preview-12-2025',
    'gemini-2.0-flash-exp',
  ];

  static String _apiKey = '';
  static String _liveModel = defaultModel;

  static String get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey.trim().isNotEmpty;

  static String get liveModel =>
      _liveModel.trim().isEmpty ? defaultModel : _liveModel.trim();

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_key) ?? '';
    _liveModel = prefs.getString(_modelKey) ?? defaultModel;
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

  static Future<void> saveModel(String model) async {
    final trimmed = model.trim();
    final prefs = await SharedPreferences.getInstance();
    _liveModel = trimmed.isEmpty ? defaultModel : trimmed;
    await prefs.setString(_modelKey, _liveModel);
  }

  static String get maskedApiKey {
    if (!hasApiKey) return 'Not configured';
    if (_apiKey.length <= 8) return _apiKey;
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }
}
