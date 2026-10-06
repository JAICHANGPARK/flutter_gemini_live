import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:gemini_live/gemini_live.dart';

/// Wraps the Gemini Live session used by the chat demo.
class ChatLiveService {
  /// Opens a Live session with the chat demo's configuration.
  Future<LiveSession> connect(LiveCallbacks callbacks) async {
    final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
    final modelToUse = ApiKeyStore.liveModel.isNotEmpty
        ? ApiKeyStore.liveModel
        : kLatestRealtimeLiveModel;

    // Initiate the connection with specified parameters.
    final session = await genAI.live.connect(
      LiveConnectParameters(
        model: modelToUse,
        config: buildExampleAudioGenerationConfig(),
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
        // Provide system instructions to guide the model's behavior.
        systemInstruction: Content(
          parts: [
            Part(
              text:
                  "You are a helpful AI assistant. "
                  "Your goal is to provide comprehensive, detailed, and well-structured answers. Always explain the background, key concepts, and provide illustrative examples. Do not give short or brief answers."
                  "**You must respond in the same language that the user uses for their question.** For example, if the user asks a question in Korean, you must reply in Korean. "
                  "If they ask in Japanese, reply in Japanese.",
            ),
          ],
        ),
        // Define callbacks to handle WebSocket events.
        callbacks: callbacks,
      ),
    );
    return session;
  }

  /// Sends a complete user turn to the model.
  void sendUserTurn(LiveSession session, List<Part> parts) {
    session.sendMessage(
      LiveClientMessage(
        clientContent: LiveClientContent(
          turns: [Content(role: "user", parts: parts)],
          turnComplete: true,
        ),
      ),
    );
  }
}
