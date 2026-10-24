import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../domain/models/vn_sdk_chapter.dart';

/// Manages the Gemini Live WebSocket session and visual novel tools
/// for Hikari (ヒカリ).
class VnLiveService {
  LiveSession? _session;
  String _activeModel = '';
  int _sessionGeneration = 0;

  bool get isConnected => _session != null && !_session!.isClosed;
  String get activeModel => _activeModel;

  static final List<Tool> vnTools = [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          name: 'set_character_emotion',
          description:
              'Update Hikari\'s anime facial expression, physical stage motion, and affection points while speaking.',
          parameters: {
            'type': 'OBJECT',
            'properties': {
              'emotion': {
                'type': 'STRING',
                'description': 'Character facial expression and pose.',
                'enum': [
                  'normal',
                  'happy',
                  'explaining',
                  'surprised',
                  'thinking',
                ],
              },
              'motion': {
                'type': 'STRING',
                'description': 'Physical stage animation to trigger.',
                'enum': [
                  'idle',
                  'nod',
                  'jump',
                  'tilt',
                  'bow',
                  'flustered_shake',
                ],
              },
              'affection_delta': {
                'type': 'INTEGER',
                'description':
                    'Change in affection points (-5 to +15) based on the conversation mood.',
              },
            },
            'required': ['emotion'],
          },
        ),
        FunctionDeclaration(
          name: 'show_sdk_showcase',
          description:
              'Display a holographic code & architecture card explaining a specific flutter_gemini_live feature.',
          parameters: {
            'type': 'OBJECT',
            'properties': {
              'topic_id': {
                'type': 'STRING',
                'description': 'SDK topic identifier.',
                'enum': [
                  'intro',
                  'audio_barge_in',
                  'tools',
                  'widgets_and_more',
                ],
              },
            },
            'required': ['topic_id'],
          },
        ),
        FunctionDeclaration(
          name: 'change_background_scene',
          description:
              'Switch the visual novel background location to match the atmosphere.',
          parameters: {
            'type': 'OBJECT',
            'properties': {
              'scene_id': {
                'type': 'STRING',
                'enum': ['tokyo_conf', 'akiba_lab', 'sakura_sunset'],
              },
            },
            'required': ['scene_id'],
          },
        ),
      ],
    ),
  ];

  Future<LiveSession> connect({
    required String voiceName,
    required String systemInstruction,
    required void Function() onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) async {
    close();
    final currentGen = ++_sessionGeneration;
    final genAI = GoogleGenAI(
      apiKey: ApiKeyStore.apiKey,
      logger: (msg) => debugPrint('[AnimeVnWS] $msg'),
    );

    final preferredModel = ApiKeyStore.liveModel.isNotEmpty
        ? ApiKeyStore.liveModel
        : kLatestRealtimeLiveModel;

    // Candidate native audio Live models in priority order so if a preview
    // model name is unavailable on the user's endpoint, we fail over in ~200ms
    // instead of timing out after 10s.
    final candidateModels = <String>{
      preferredModel,
      'gemini-2.5-flash-native-audio-preview-12-2025',
      'gemini-3.1-flash-live-preview',
      'gemini-2.0-flash-exp',
    }.toList();

    Object? lastError;

    for (var i = 0; i < candidateModels.length; i++) {
      final modelToTry = candidateModels[i];
      var handshakeCompleted = false;
      final earlyCloseCompleter = Completer<LiveSession>();

      try {
        debugPrint(
          '🌸 [AnimeVnWS] Connecting with model: $modelToTry (voice: $voiceName)...',
        );

        final connectFuture = genAI.live.connect(
          LiveConnectParameters(
            model: modelToTry,
            config: buildExampleAudioGenerationConfig(
              temperature: 0.90,
              voiceName: voiceName,
            ),
            systemInstruction: Content(
              parts: [
                Part(
                  text: systemInstruction.isNotEmpty
                      ? systemInstruction
                      : VnScenarioCatalog.systemInstructionJa,
                ),
              ],
            ),
            inputAudioTranscription: AudioTranscriptionConfig(),
            outputAudioTranscription: AudioTranscriptionConfig(),
            callbacks: LiveCallbacks(
              onOpen: () {
                if (currentGen != _sessionGeneration) return;
                onOpen();
              },
              onMessage: (msg) {
                if (currentGen != _sessionGeneration) return;
                onMessage(msg);
              },
              onError: (err, st) {
                if (currentGen != _sessionGeneration) return;
                if (!handshakeCompleted && !earlyCloseCompleter.isCompleted) {
                  earlyCloseCompleter.completeError(err, st);
                  return;
                }
                onError(err, st);
              },
              onClose: (code, reason) {
                if (currentGen != _sessionGeneration) return;
                if (!handshakeCompleted && !earlyCloseCompleter.isCompleted) {
                  earlyCloseCompleter.completeError(
                    Exception(
                      'WebSocket closed during setup (code: $code, reason: ${reason ?? "unknown"})',
                    ),
                  );
                  return;
                }
                onClose(code, reason);
              },
            ),
          ),
        );

        // Prevent unhandled async error if earlyCloseCompleter wins the race
        connectFuture.ignore();

        final session = await Future.any<LiveSession>([
          connectFuture,
          earlyCloseCompleter.future,
        ]);

        handshakeCompleted = true;
        _session = session;
        _activeModel = modelToTry;
        debugPrint('✅ [AnimeVnWS] Connected & setupComplete with $modelToTry');
        return session;
      } catch (e) {
        lastError = e;
        debugPrint(
          '⚠️ [AnimeVnWS] Model $modelToTry failed handshake: $e',
        );
      }
    }

    throw lastError ?? Exception('Failed to connect to Gemini Live API.');
  }

  void sendText(String text) {
    final s = _session;
    if (s == null || s.isClosed) return;
    // Use sendRealtimeText (`{"realtimeInput":{"text":...}}`) which is supported
    // across all Gemini Live models (3.1, 2.5, 3.8) without duplicate field errors.
    s.sendRealtimeText(text);
  }

  void sendAudio(Uint8List pcm16kBytes) {
    final s = _session;
    if (s == null || s.isClosed) return;
    s.sendAudio(pcm16kBytes);
  }

  void sendToolResponse({
    required String id,
    required String name,
    required Map<String, dynamic> response,
  }) {
    final s = _session;
    if (s == null || s.isClosed) return;
    s.sendToolResponse(
      functionResponses: [
        FunctionResponse(
          id: id,
          name: name,
          response: response,
        ),
      ],
    );
  }

  void close() {
    _sessionGeneration++;
    try {
      _session?.close();
    } catch (_) {}
    _session = null;
  }
}
