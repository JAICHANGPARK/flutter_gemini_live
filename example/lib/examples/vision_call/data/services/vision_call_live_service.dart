import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Owns the Gemini Live WebSocket session and every outbound message.
class VisionCallLiveService {
  static const _audioMimeType = 'audio/pcm;rate=16000';

  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Opens a session. The returned session is not stored until [attach].
  Future<LiveSession> connect({
    required String model,
    required String promptText,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) {
    final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);

    final systemInstruction = Content(parts: [Part(text: promptText)]);

    return genAI.live.connect(
      LiveConnectParameters(
        model: model,
        systemInstruction: systemInstruction,
        config: GenerationConfig(
          responseModalities: const [Modality.AUDIO],
          mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(
                voiceName: ApiKeyStore.voice,
              ),
            ),
          ),
          temperature: 0.7,
        ),
        realtimeInputConfig: RealtimeInputConfig(
          automaticActivityDetection: AutomaticActivityDetection(
            disabled: false,
            startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
            endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
            prefixPaddingMs: 250,
            silenceDurationMs: 500,
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

  void sendAudioChunk(Uint8List chunk) {
    _session!.sendRealtimeInput(
      audio: Blob(mimeType: _audioMimeType, data: base64Encode(chunk)),
    );
  }

  void sendVideoFrame(Uint8List jpegBytes) {
    final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(jpegBytes));

    _session!.sendRealtimeInput(video: blob);
  }

  /// Closes the session (if any) without clearing the handle.
  Future<void>? close() => _session?.close();
}
