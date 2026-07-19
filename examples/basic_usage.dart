import 'package:gemini_live/gemini_live.dart';

/// Example: Basic Live API Usage
///
/// This example demonstrates the basic usage of the Gemini Live API
/// including connecting, sending text, and handling responses.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  // Create Live Service
  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  // Connect to Live API
  final session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Live API');
        },
        onMessage: (message) {
          _handleMessage(message);
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed: code=$code, reason=$reason');
        },
      ),
      config: GenerationConfig(
        temperature: 0.7,
        responseModalities: [Modality.TEXT],
      ),
      systemInstruction: Content(
        parts: [Part(text: 'You are a helpful assistant.')],
      ),
    ),
  );

  // Send text message
  print('💬 Sending: Hello, how are you?');
  session.sendText('Hello, how are you?');

  // Keep the connection alive for a while
  await Future.delayed(Duration(seconds: 10));

  // Close the connection
  await session.close();
  print('👋 Session closed');
}

void _handleMessage(LiveServerMessage message) {
  // Handle text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Handle audio data
  if (message.data != null) {
    print('🔊 Received audio data: ${message.data!.length} chars');
  }

  // Handle tool calls
  if (message.toolCall != null) {
    print(
      '🔧 Tool call received: ${message.toolCall!.functionCalls?.length} functions',
    );
    for (final call in message.toolCall!.functionCalls ?? []) {
      print('  - ${call.name} (id: ${call.id})');
    }
  }

  // Handle tool call cancellation
  if (message.toolCallCancellation != null) {
    print('❌ Tool call cancelled: ${message.toolCallCancellation!.ids}');
  }

  // Handle session resumption update
  if (message.sessionResumptionUpdate != null) {
    print(
      '🔄 Session resumption update: ${message.sessionResumptionUpdate!.newHandle}',
    );
  }

  // Handle voice activity
  if (message.voiceActivity != null) {
    print(
      '🎤 Voice activity: speechActive=${message.voiceActivity!.speechActive}',
    );
  }

  // Handle go away (server will disconnect soon)
  if (message.goAway != null) {
    print(
      '⏰ Server will disconnect: ${message.goAway!.reason} (${message.goAway!.timeRemaining}s remaining)',
    );
  }

  // Handle usage metadata
  if (message.usageMetadata != null) {
    print(
      '📊 Tokens: ${message.usageMetadata!.totalTokenCount} ' +
          '(prompt: ${message.usageMetadata!.promptTokenCount}, ' +
          'response: ${message.usageMetadata!.responseTokenCount})',
    );
  }
}
