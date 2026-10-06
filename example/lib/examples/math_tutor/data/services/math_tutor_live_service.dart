import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../domain/models/math_curriculum_level.dart';

/// Owns the Gemini Live WebSocket session and every outbound message.
class MathTutorLiveService {
  static const _audioMimeType = 'audio/pcm;rate=16000';

  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Composes the final system instruction: persona + language + curriculum.
  static String buildSystemInstruction({
    required String customInstruction,
    required AppLanguage language,
    required MathCurriculumLevel curriculum,
  }) {
    final languageInstruction = switch (language) {
      AppLanguage.ko =>
        '\n\n[Active Student Language]: Korean (한국어). Speak and answer strictly in Korean.',
      AppLanguage.en =>
        '\n\n[Active Student Language]: English. Speak and answer strictly in English.',
      AppLanguage.ja =>
        '\n\n[Active Student Language]: Japanese (日本語). Speak and answer strictly in Japanese.',
      AppLanguage.zh =>
        '\n\n[Active Student Language]: Chinese (中文). Speak and answer strictly in Chinese.',
    };

    final curriculumHint = curriculum != MathCurriculumLevel.auto
        ? '\n\n[Active Curriculum Focus Mode]: ${curriculum.promptHint}'
        : '\n\n[Active Curriculum Focus Mode]: Automatically detect problem curriculum grade and difficulty from the problem.';

    return '$customInstruction$languageInstruction$curriculumHint';
  }

  Future<void> connect({
    required String model,
    required String systemInstruction,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) async {
    final genAI = GoogleGenAI(
      apiKey: ApiKeyStore.apiKey,
      logger: (msg) => debugPrint('[GeminiLiveWS] $msg'),
    );

    debugPrint('🔌 Attempting Gemini Live connection with model: $model');

    final session = await genAI.live.connect(
      LiveConnectParameters(
        model: model,
        config: GenerationConfig(
          responseModalities: const [Modality.AUDIO],
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(
                voiceName: ApiKeyStore.voice.isNotEmpty
                    ? ApiKeyStore.voice
                    : 'Charon', // 차분하고 지적인 톤
              ),
            ),
          ),
          // Include thinking config for models that support it
          thinkingConfig: model.contains('thinking')
              ? ThinkingConfig(
                  thinkingLevel: ThinkingLevel.HIGH,
                  includeThoughts: true,
                )
              : null,
        ),
        systemInstruction: Content(parts: [Part(text: systemInstruction)]),
        inputAudioTranscription: AudioTranscriptionConfig(
          languageCodes: const ['ko-KR', 'en-US', 'ja-JP'],
        ),
        outputAudioTranscription: AudioTranscriptionConfig(),
        realtimeInputConfig: RealtimeInputConfig(
          automaticActivityDetection: AutomaticActivityDetection(
            disabled: false,
            startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
            endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
            prefixPaddingMs: 250,
            silenceDurationMs: 800,
          ),
          activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
        ),
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
    _session!.sendRealtimeInput(
      audio: Blob(mimeType: _audioMimeType, data: base64Encode(chunk)),
    );
  }

  /// Streams a JPEG frame as realtime video input (no model turn).
  void sendVideoFrame(Uint8List jpegBytes) {
    _session!.sendRealtimeInput(video: _jpegBlob(jpegBytes));
  }

  /// Sends the problem image plus [prompt] in one client-content turn so the
  /// model receives the exact image atomically with the question.
  void sendProblemImage(Uint8List jpegBytes, String prompt) {
    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: [
            Part(inlineData: _jpegBlob(jpegBytes)),
            Part(text: prompt),
          ],
        ),
      ],
      turnComplete: true,
    );
  }

  void sendUserText(String text) {
    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: [Part(text: text)],
        ),
      ],
      turnComplete: true,
    );
  }

  Blob _jpegBlob(Uint8List bytes) =>
      Blob(mimeType: 'image/jpeg', data: base64Encode(bytes));

  void close() => _session?.close();
}
