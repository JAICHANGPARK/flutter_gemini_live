import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyStore {
  static const _key = 'gemini_api_key';
  static const _modelKey = 'gemini_live_model';
  static const _voiceKey = 'gemini_live_voice';
  static const _audioDeviceIdKey = 'gemini_selected_audio_device_id';
  static const _audioDeviceLabelKey = 'gemini_selected_audio_device_label';
  static const _cameraFlippedKey = 'gemini_camera_flipped';

  static const String defaultModel = 'gemini-3.1-flash-live-preview';
  static const List<String> availableModels = [
    'gemini-3.1-flash-live-preview',
    'gemini-3.5-live-translate-preview',
    'gemini-2.5-flash-native-audio-preview-12-2025',
    'gemini-2.0-flash-exp',
  ];

  static const String defaultVoice = 'Puck';
  static const List<Map<String, String>> availableVoices = [
    {'name': 'Puck', 'desc': 'Upbeat (경쾌함)'},
    {'name': 'Charon', 'desc': 'Informative (차분/지적)'},
    {'name': 'Kore', 'desc': 'Firm (단호함/차분)'},
    {'name': 'Fenrir', 'desc': 'Excitable (활기참)'},
    {'name': 'Aoede', 'desc': 'Breezy (시원함)'},
    {'name': 'Leda', 'desc': 'Youthful (산뜻함)'},
    {'name': 'Orus', 'desc': 'Firm (묵직함)'},
    {'name': 'Zephyr', 'desc': 'Bright (밝음)'},
    {'name': 'Callirrhoe', 'desc': 'Easy-going (편안함)'},
    {'name': 'Enceladus', 'desc': 'Breathy (부드러움)'},
    {'name': 'Iapetus', 'desc': 'Clear (명료함)'},
    {'name': 'Umbriel', 'desc': 'Easy-going (온화함)'},
    {'name': 'Algieba', 'desc': 'Smooth (부드러움)'},
    {'name': 'Despina', 'desc': 'Smooth (자연스러움)'},
    {'name': 'Erinome', 'desc': 'Clear (맑음)'},
    {'name': 'Algenib', 'desc': 'Gravelly (중저음)'},
    {'name': 'Rasalgethi', 'desc': 'Informative (안내형)'},
    {'name': 'Laomedeia', 'desc': 'Upbeat (밝고 경쾌)'},
    {'name': 'Achernar', 'desc': 'Soft (차분하고 부드러움)'},
    {'name': 'Alnilam', 'desc': 'Firm (신뢰감)'},
    {'name': 'Schedar', 'desc': 'Even (균형 잡힘)'},
    {'name': 'Gacrux', 'desc': 'Mature (성숙함)'},
    {'name': 'Pulcherrima', 'desc': 'Forward (당당함)'},
    {'name': 'Achird', 'desc': 'Friendly (친근함)'},
    {'name': 'Zubenelgenubi', 'desc': 'Casual (편안한 대화체)'},
    {'name': 'Vindemiatrix', 'desc': 'Gentle (따뜻하고 온화)'},
    {'name': 'Sadachbia', 'desc': 'Lively (생동감)'},
    {'name': 'Sadaltager', 'desc': 'Knowledgeable (전문적)'},
    {'name': 'Sulafat', 'desc': 'Warm (포근함)'},
  ];

  static String _apiKey = '';
  static String _liveModel = defaultModel;
  static String _voice = defaultVoice;
  static String _audioDeviceId = '';
  static String _audioDeviceLabel = '';
  static bool _isCameraFlipped = true;

  static String get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey.trim().isNotEmpty;

  static String get liveModel =>
      _liveModel.trim().isEmpty ? defaultModel : _liveModel.trim();

  static String get voice =>
      _voice.trim().isEmpty ? defaultVoice : _voice.trim();

  static String get audioDeviceId => _audioDeviceId;
  static String get audioDeviceLabel => _audioDeviceLabel;
  static bool get isCameraFlipped => _isCameraFlipped;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_key) ?? '';
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final systemEnvKey = !kIsWeb ? (Platform.environment['GEMINI_API_KEY'] ?? '') : '';

    if (storedKey.trim().isNotEmpty) {
      _apiKey = storedKey.trim();
    } else if (envKey.trim().isNotEmpty) {
      _apiKey = envKey.trim();
    } else {
      _apiKey = systemEnvKey.trim();
    }

    _liveModel = prefs.getString(_modelKey) ?? defaultModel;
    _voice = prefs.getString(_voiceKey) ?? defaultVoice;
    _audioDeviceId = prefs.getString(_audioDeviceIdKey) ?? '';
    _audioDeviceLabel = prefs.getString(_audioDeviceLabelKey) ?? '';
    _isCameraFlipped = prefs.getBool(_cameraFlippedKey) ?? true;
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

  static Future<void> saveVoice(String voice) async {
    final trimmed = voice.trim();
    final prefs = await SharedPreferences.getInstance();
    _voice = trimmed.isEmpty ? defaultVoice : trimmed;
    await prefs.setString(_voiceKey, _voice);
  }

  static Future<void> saveAudioDevice(String id, String label) async {
    final prefs = await SharedPreferences.getInstance();
    _audioDeviceId = id.trim();
    _audioDeviceLabel = label.trim();
    if (_audioDeviceId.isEmpty) {
      await prefs.remove(_audioDeviceIdKey);
      await prefs.remove(_audioDeviceLabelKey);
    } else {
      await prefs.setString(_audioDeviceIdKey, _audioDeviceId);
      await prefs.setString(_audioDeviceLabelKey, _audioDeviceLabel);
    }
  }

  static Future<void> saveCameraFlipped(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isCameraFlipped = value;
    await prefs.setBool(_cameraFlippedKey, value);
  }

  static String get maskedApiKey {
    if (!hasApiKey) return 'Not configured';
    if (_apiKey.length <= 8) return _apiKey;
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }
}
