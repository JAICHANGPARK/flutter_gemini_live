import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../domain/note_prompts.dart';
import 'smart_notetaker_mic_service.dart';

/// Owns the Gemini Live WebSocket session and every outbound message.
class SmartNotetakerLiveService {
  static const int _audioSampleRate = SmartNotetakerMicService.sampleRate;

  LiveSession? _session;

  bool get hasSession => _session != null;

  Future<void> connect({
    required String targetLang,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) async {
    final systemPrompt = buildNoteSystemPrompt(targetLang);

    final genAI = GoogleGenAI(
      apiKey: ApiKeyStore.apiKey,
      logger: (msg) => debugPrint('[GeminiLive Note] $msg'),
    );
    final modelToUse = ApiKeyStore.liveModel.isNotEmpty
        ? ApiKeyStore.liveModel
        : kCompatibilityLiveModel;

    final session = await genAI.live.connect(
      LiveConnectParameters(
        model: modelToUse,
        config: GenerationConfig(
          responseModalities: const [Modality.AUDIO],
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(
                voiceName: ApiKeyStore.voice,
              ),
            ),
          ),
          temperature: 0.3,
        ),
        realtimeInputConfig: RealtimeInputConfig(
          automaticActivityDetection: AutomaticActivityDetection(
            disabled: false,
            startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
            endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_HIGH,
            prefixPaddingMs: 100,
            silenceDurationMs: 300,
          ),
        ),
        systemInstruction: Content(parts: [Part(text: systemPrompt)]),
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
    _session = session;
  }

  void sendAudioChunk(Uint8List chunk) {
    final blob = Blob(
      mimeType: 'audio/pcm;rate=$_audioSampleRate',
      data: base64Encode(chunk),
    );
    _session!.sendRealtimeInput(audio: blob);
  }

  void sendWrapUpRequest() {
    _session!.sendClientContent(
      turns: [
        Content(parts: [Part(text: kWrapUpSummaryPrompt)]),
      ],
      turnComplete: true,
    );
  }

  void close() {
    _session?.close();
    _session = null;
  }
}
