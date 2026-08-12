import 'package:gemini_live/gemini_live.dart';

/// Example: Grounding with Google Maps & Custom Audio Transcription Config
///
/// This example demonstrates how to configure Google Maps grounding
/// (places & routing) and audio transcription settings with custom vocabulary
/// in the Gemini Live API.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  // Connect to Live API with Google Maps grounding tool and custom vocabulary
  final session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Gemini Live API');
        },
        onMessage: (message) {
          final text = message.text;
          if (text != null) {
            print('🤖 Gemini: $text');
          }
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed');
        },
      ),
      config: GenerationConfig(
        responseModalities: [Modality.TEXT, Modality.AUDIO],
        audioTranscriptionConfig: AudioTranscriptionConfig(
          customVocabulary: ['Seoul Station', 'Gangnam', 'Flutter Live'],
        ),
      ),
      tools: [
        Tool(
          googleMaps: GoogleMaps(
            groundingTypes: ['places', 'routing'],
          ),
        ),
      ],
    ),
  );

  print('💬 Sending prompt asking for place information...');
  session.sendText('Can you recommend top places to visit near Gangnam Station and how to get there?');

  // Wait for response and close after 10 seconds
  await Future.delayed(const Duration(seconds: 10));
  await session.close();
}
