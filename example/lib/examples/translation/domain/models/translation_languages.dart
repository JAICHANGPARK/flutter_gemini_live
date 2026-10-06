/// Supported target languages for Gemini Live Translation.
const List<Map<String, String>> kTranslationLanguages = [
  {'code': 'ko', 'name': '한국어 (Korean)', 'flag': '🇰🇷'},
  {'code': 'en', 'name': 'English (영어)', 'flag': '🇺🇸'},
  {'code': 'ja', 'name': '日本語 (Japanese)', 'flag': '🇯🇵'},
  {'code': 'zh-Hans', 'name': '简体中文 (Chinese)', 'flag': '🇨🇳'},
  {'code': 'es', 'name': 'Español (Spanish)', 'flag': '🇪🇸'},
  {'code': 'fr', 'name': 'Français (French)', 'flag': '🇫🇷'},
  {'code': 'de', 'name': 'Deutsch (German)', 'flag': '🇩🇪'},
  {'code': 'vi', 'name': 'Tiếng Việt (Vietnamese)', 'flag': '🇻🇳'},
  {'code': 'th', 'name': 'ไทย (Thai)', 'flag': '🇹🇭'},
  {'code': 'id', 'name': 'Bahasa Indonesia (Indonesian)', 'flag': '🇮🇩'},
  {'code': 'ru', 'name': 'Русский (Russian)', 'flag': '🇷🇺'},
  {'code': 'it', 'name': 'Italiano (Italian)', 'flag': '🇮🇹'},
  {'code': 'pt-BR', 'name': 'Português (Portuguese)', 'flag': '🇧🇷'},
  {'code': 'ar', 'name': 'العربية (Arabic)', 'flag': '🇸🇦'},
  {'code': 'hi', 'name': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
];

/// Looks up the language entry for [code]; unknown codes fall back to an entry
/// that uses the code itself as name.
Map<String, String> findTranslationLanguage(String code) {
  return kTranslationLanguages.firstWhere(
    (l) => l['code'] == code,
    orElse: () => {'code': code, 'name': code, 'flag': '🌐'},
  );
}
