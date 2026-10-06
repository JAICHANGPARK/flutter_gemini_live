import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Owns the Gemini Live WebSocket session and every outbound message.
class RealtimeMediaLiveService {
  static const _audioMimeType = 'audio/pcm;rate=16000';

  final GoogleGenAI _genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);

  /// The active session; assigned by the view model once `connect` resolves.
  LiveSession? session;

  Future<LiveSession> connect({
    required bool manualActivityMode,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) {
    return _genAI.live.connect(
      LiveConnectParameters(
        model: kLatestRealtimeLiveModel,
        config: buildExampleAudioGenerationConfig(temperature: 0.7),
        realtimeInputConfig: manualActivityMode
            ? RealtimeInputConfig(
                automaticActivityDetection: AutomaticActivityDetection(
                  disabled: true,
                ),
              )
            : RealtimeInputConfig(
                automaticActivityDetection: AutomaticActivityDetection(
                  disabled: false,
                  startOfSpeechSensitivity:
                      StartSensitivity.START_SENSITIVITY_HIGH,
                  endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
                  prefixPaddingMs: 300,
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

  void sendRealtimeText(String text) => session!.sendRealtimeText(text);

  void sendActivityStart() => session!.sendActivityStart();

  void sendActivityEnd() => session!.sendActivityEnd();

  void sendAudioStreamEnd() => session!.sendAudioStreamEnd();

  void sendVideo(Uint8List bytes) => session!.sendVideo(bytes);

  /// Sends three tiny dummy PCM blobs via `sendMediaChunks`; returns the
  /// number of chunks sent.
  int sendDemoMediaChunks() {
    final chunks = [
      Blob(mimeType: 'audio/pcm', data: base64Encode([1, 2, 3, 4, 5])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([6, 7, 8, 9, 10])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([11, 12, 13, 14, 15])),
    ];

    session!.sendMediaChunks(chunks);
    return chunks.length;
  }

  void sendAudioChunk(Uint8List chunk) {
    final blob = Blob(mimeType: _audioMimeType, data: base64Encode(chunk));
    session!.sendRealtimeInput(audio: blob);
  }

  void sendVideoFrame(Uint8List bytes) {
    final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(bytes));
    session!.sendRealtimeInput(video: blob);
  }

  /// Mirrors `_session?.close()`; completes immediately when no session.
  Future<void> close() async => await session?.close();
}
