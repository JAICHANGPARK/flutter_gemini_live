import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Owns the Gemini Live WebSocket session and every outbound message.
class LiveApiLiveService {
  LiveApiLiveService();

  GoogleGenAI? _genAI;
  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Whether the underlying WebSocket transport forwards handshake HTTP headers
  /// (`true` on `dart:io`, `false` on Web browsers).
  bool get supportsHeaders =>
      (_genAI ?? GoogleGenAI(apiKey: ApiKeyStore.apiKey)).live.supportsHeaders;

  /// Opens a session. Does NOT store it; call [attach] with the result so the
  /// caller controls ordering relative to its own state updates.
  Future<LiveSession> connect({
    required bool enableRealtimeConfig,
    required bool enableTranscription,
    required bool useSmartTranscription,
    required bool enableSessionResumption,
    required bool enableContextCompression,
    bool enableServerTimeout = true,
    required String? sessionHandle,
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) async {
    final modelToUse = ApiKeyStore.liveModel.isNotEmpty
        ? ApiKeyStore.liveModel
        : kCompatibilityLiveModel;

    // Recreate GoogleGenAI with latest API key, optional GenAICredentials
    // (dynamic Bearer token + x-goog-user-project), and isolated HttpOptions.
    final genAI = GoogleGenAI(
      apiKey: ApiKeyStore.apiKey,
      credentials: ApiKeyStore.credentials,
      httpOptions: HttpOptions(
        timeout: enableServerTimeout ? 30000 : null,
        headers: const {'x-client-source': 'flutter_gemini_live_example'},
      ),
    );
    _genAI = genAI;

    return genAI.live.connect(
      LiveConnectParameters(
        model: modelToUse,
        config: buildExampleAudioGenerationConfig(temperature: 0.7),
        systemInstruction:
            'You are a helpful AI assistant demonstrating advanced features.',
        // Realtime input configuration
        realtimeInputConfig: enableRealtimeConfig
            ? RealtimeInputConfig(
                automaticActivityDetection: AutomaticActivityDetection(
                  disabled: false,
                  startOfSpeechSensitivity:
                      StartSensitivity.START_SENSITIVITY_HIGH,
                  endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
                  prefixPaddingMs: 300,
                  silenceDurationMs: 500,
                ),
                activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
                turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
              )
            : null,
        // Audio transcription
        inputAudioTranscription: enableTranscription
            ? AudioTranscriptionConfig(
                mode: useSmartTranscription
                    ? AudioTranscriptionConfigMode.SMART
                    : AudioTranscriptionConfigMode.VERBATIM,
              )
            : null,
        outputAudioTranscription: enableTranscription
            ? AudioTranscriptionConfig(
                mode: useSmartTranscription
                    ? AudioTranscriptionConfigMode.SMART
                    : AudioTranscriptionConfigMode.VERBATIM,
              )
            : null,
        // Session resumption
        sessionResumption: enableSessionResumption && sessionHandle != null
            ? SessionResumptionConfig(handle: sessionHandle)
            : null,
        // Context window compression (supports int or String token counts)
        contextWindowCompression: enableContextCompression
            ? ContextWindowCompressionConfig(
                triggerTokens: 10000,
                slidingWindow: SlidingWindow(targetTokens: 5000),
              )
            : null,
        // Custom billing / observability labels
        labels: const {
          'app': 'gemini_live_example',
          'screen': 'live_api',
        },
        // Session-level HTTP / WebSocket transport options (with X-Server-Timeout)
        httpOptions: HttpOptions(
          timeout: enableServerTimeout ? 30000 : null,
          headers: const {'x-example-screen': 'live_api'},
        ),
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

  void sendText(String text) => _session!.sendText(text);

  void sendClientContent() {
    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: [Part(text: 'Remember: my favorite color is blue.')],
        ),
        Content(
          role: 'model',
          parts: [
            Part(text: 'I\'ll remember that your favorite color is blue.'),
          ],
        ),
        Content(
          role: 'user',
          parts: [Part(text: 'What\'s my favorite color?')],
        ),
      ],
      turnComplete: true,
    );
  }

  void sendRealtimeInput() {
    _session!.sendRealtimeInput(
      text: 'This is realtime text input',
      audioStreamEnd: true,
    );
  }

  void sendActivityStart() => _session!.sendActivityStart();

  void sendActivityEnd() => _session!.sendActivityEnd();

  /// Sends an in-session context update (`LiveClientContextUpdate`) to update
  /// `systemInstruction` or `tools` dynamically without reconnecting.
  void sendContextUpdate({String? systemInstruction, List<Tool>? tools}) {
    _session!.sendContextUpdate(
      systemInstruction: systemInstruction,
      tools: tools,
    );
  }

  void close() => _session?.close();
}
