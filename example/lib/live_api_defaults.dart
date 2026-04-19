import 'package:gemini_live/gemini_live.dart';

const String kCompatibilityLiveModel =
    'gemini-2.5-flash-native-audio-preview-12-2025';
const String kLatestRealtimeLiveModel = 'gemini-3.1-flash-live-preview';

GenerationConfig buildExampleAudioGenerationConfig({
  double? temperature,
  int? maxOutputTokens,
  ThinkingConfig? thinkingConfig,
  bool? enableAffectiveDialog,
}) {
  return GenerationConfig(
    temperature: temperature,
    maxOutputTokens: maxOutputTokens,
    responseModalities: const [Modality.AUDIO],
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
