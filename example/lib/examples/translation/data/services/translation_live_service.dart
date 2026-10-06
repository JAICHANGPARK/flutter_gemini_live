import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import 'translation_mic_service.dart';

/// Owns the Gemini Live translation session and every outbound message.
class TranslationLiveService {
  static const String modelName = 'gemini-3.5-live-translate-preview';
  static const int _audioSampleRate = TranslationMicService.sampleRate;

  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Opens the session. The caller adopts it with [attach] once it is ready
  /// (the session is intentionally not stored before that).
  Future<LiveSession> connect({
    required String targetLanguageCode,
    required bool echoTargetLanguage,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) {
    final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
    return genAI.live.connect(
      LiveConnectParameters(
        model: modelName,
        config: GenerationConfig(
          responseModalities: const [Modality.AUDIO],
          translationConfig: TranslationConfig(
            targetLanguageCode: targetLanguageCode,
            echoTargetLanguage: echoTargetLanguage,
          ),
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(
                voiceName: ApiKeyStore.voice,
              ),
            ),
          ),
        ),
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
        callbacks: LiveCallbacks(
          onOpen: onOpen,
          onMessage: onMessage,
          onError: onError,
          onClose: onClose,
        ),
      ),
    );
  }

  void attach(LiveSession session) => _session = session;

  void detach() => _session = null;

  void sendAudio(Uint8List chunk) {
    final blob = Blob(
      mimeType: 'audio/pcm;rate=$_audioSampleRate',
      data: base64Encode(chunk),
    );
    _session!.sendRealtimeInput(audio: blob);
  }

  /// Sends [length] bytes of silence in place of a mic chunk.
  void sendSilence(int length) {
    _session!.sendRealtimeInput(
      audio: Blob(
        mimeType: 'audio/pcm;rate=$_audioSampleRate',
        data: base64Encode(Uint8List(length)),
      ),
    );
  }

  Future<void>? close() => _session?.close();
}
