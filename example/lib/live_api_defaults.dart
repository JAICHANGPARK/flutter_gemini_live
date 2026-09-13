import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';

const String kCompatibilityLiveModel = 'gemini-3.1-flash-live-preview';
const String kLatestRealtimeLiveModel = 'gemini-3.1-flash-live-preview';

GenerationConfig buildExampleAudioGenerationConfig({
  double? temperature,
  int? maxOutputTokens,
  String? voiceName,
  ThinkingConfig? thinkingConfig,
  bool? enableAffectiveDialog,
}) {
  final voice = voiceName ?? ApiKeyStore.voice;
  return GenerationConfig(
    temperature: temperature ?? 0.7,
    maxOutputTokens: maxOutputTokens,
    responseModalities: const [Modality.AUDIO],
    speechConfig: SpeechConfig(
      voiceConfig: VoiceConfig(
        prebuiltVoiceConfig: PrebuiltVoiceConfig(
          voiceName: voice,
        ),
      ),
    ),
    thinkingConfig: thinkingConfig,
    enableAffectiveDialog: enableAffectiveDialog,
  );
}

String? visibleModelText(LiveServerMessage message) {
  final transcript = message.serverContent?.outputTranscription?.text;
  if (transcript != null && transcript.isNotEmpty) {
    return transcript;
  }
  return message.text;
}
