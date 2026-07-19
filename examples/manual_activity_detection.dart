import 'package:gemini_live/gemini_live.dart';

/// Example: Manual Activity Detection
///
/// This example demonstrates how to use manual activity detection
/// when automatic VAD (Voice Activity Detection) is disabled.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

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
          print('🔒 Connection closed');
        },
      ),
      config: GenerationConfig(
        temperature: 0.7,
        responseModalities: [Modality.TEXT],
      ),
      // Disable automatic activity detection - client must send signals
      realtimeInputConfig: RealtimeInputConfig(
        automaticActivityDetection: AutomaticActivityDetection(
          disabled: true, // Disable automatic detection
        ),
        // When automatic detection is disabled, client controls turn handling
        activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
        turnCoverage: TurnCoverage.TURN_INCLUDES_ONLY_ACTIVITY,
      ),
    ),
  );

  print('🎙️ Manual Activity Detection Mode');
  print('   Automatic VAD is disabled. You must manually signal activity.');
  print('');
  print('📝 Instructions:');
  print('   1. Call sendActivityStart() when user starts speaking');
  print('   2. Send audio data while user is speaking');
  print('   3. Call sendActivityEnd() when user stops speaking');
  print('');

  // Simulate user interaction with manual activity detection
  await _simulateManualActivityDetection(session);

  await Future.delayed(Duration(seconds: 3));
  await session.close();
  print('👋 Session closed');
}

Future<void> _simulateManualActivityDetection(LiveSession session) async {
  print('🎙️ User started speaking...');

  // Signal that user activity has started
  session.sendActivityStart();
  print('   📤 Sent activityStart signal');

  // Send audio chunks while user is speaking
  for (int i = 0; i < 5; i++) {
    final audioChunk = List<int>.generate(320, (index) => index % 256);
    session.sendAudio(audioChunk);
    print('   🔊 Sent audio chunk ${i + 1}/5');
    await Future.delayed(Duration(milliseconds: 100));
  }

  print('🎙️ User stopped speaking...');

  // Signal that user activity has ended
  session.sendActivityEnd();
  print('   📤 Sent activityEnd signal');

  // Wait for model response
  print('⏳ Waiting for model response...');
  await Future.delayed(Duration(seconds: 2));

  // Simulate another turn
  print('');
  print('🎙️ User started speaking again...');
  session.sendActivityStart();

  // This time send as a complete client content
  session.sendClientContent(
    turns: [
      Content(parts: [Part(text: 'Can you tell me a joke?')]),
    ],
    turnComplete: true,
  );

  session.sendActivityEnd();
  print('   📤 Sent text with activity signals');
}

void _handleMessage(LiveServerMessage message) {
  // Handle text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Handle audio data
  if (message.data != null) {
    print('🔊 Received audio: ${message.data!.length} chars');
  }

  // Handle turn completion
  if (message.serverContent?.turnComplete == true) {
    print('✅ Model turn complete');
  }

  // Handle generation completion
  if (message.serverContent?.generationComplete == true) {
    print('✅ Generation complete');
  }

  // Note: In manual mode, you won't receive voiceActivityDetectionSignal
  // or voiceActivity from server since you're handling it manually
}
