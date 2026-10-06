import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import 'media_subtitle_mic_service.dart';

/// Owns the Gemini Live Translate WebSocket session.
class MediaSubtitleLiveService {
  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Opens a session. The caller decides whether to [attach] it (the session
  /// is only adopted when the screen is still alive).
  Future<LiveSession> connect({
    required String targetLanguageCode,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) {
    final genAI = GoogleGenAI(
      apiKey: ApiKeyStore.apiKey,
      logger: (msg) => debugPrint('[GeminiLive Subtitle] $msg'),
    );

    // Dedicated continuous stream translation model: gemini-3.5-live-translate-preview
    const translationModel = 'gemini-3.5-live-translate-preview';

    return genAI.live.connect(
      LiveConnectParameters(
        model: translationModel,
        config: GenerationConfig(
          responseModalities: const [Modality.AUDIO],
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(
                voiceName: ApiKeyStore.voice,
              ),
            ),
          ),
          translationConfig: TranslationConfig(
            targetLanguageCode: targetLanguageCode,
            echoTargetLanguage: true,
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

  void sendAudioChunk(Uint8List chunk) {
    // Send 16kHz PCM blob to Gemini Live
    final blob = Blob(
      mimeType: 'audio/pcm;rate=${MediaSubtitleMicService.sampleRate}',
      data: base64Encode(chunk),
    );
    _session!.sendRealtimeInput(audio: blob);
  }

  /// Closes the session handle without forgetting it (used on dispose).
  void close() => _session?.close();

  /// Closes the session and forgets it (used on disconnect).
  void closeAndClear() {
    _session?.close();
    _session = null;
  }
}
