import 'package:gemini_live/gemini_live.dart';

/// Example: Complete Live API Features
///
/// This example demonstrates all the features available in the Gemini Live API:
/// - Function calling
/// - Realtime audio/video input
/// - Session resumption
/// - Manual activity detection
/// - Audio transcription
/// - Context window compression
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  print('🚀 Gemini Live API - Complete Features Example');
  print('=' * 50);
  print('');

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  // Track state
  final pendingFunctionCalls = <String, FunctionCall>{};
  String? currentSessionHandle;

  // Will hold the session once connected
  late final LiveSession session;

  session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-live-2.5-flash-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Live API');
          print('   User Agent: ${LiveService.dartVersion()}');
        },
        onMessage: (message) {
          _handleMessage(
            message,
            session,
            pendingFunctionCalls,
            currentSessionHandle,
          );
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed: code=$code, reason=$reason');
        },
      ),
      // Configuration
      config: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
        responseModalities: [Modality.AUDIO, Modality.TEXT],
      ),
      // System instruction
      systemInstruction: Content(
        parts: [
          Part(
            text:
                'You are a helpful AI assistant with access to weather and time functions.',
          ),
        ],
      ),
      // Tools for function calling
      tools: [Tool()],
      // Realtime input configuration
      realtimeInputConfig: RealtimeInputConfig(
        automaticActivityDetection: AutomaticActivityDetection(
          disabled: false,
          startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
          endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
          prefixPaddingMs: 300,
          silenceDurationMs: 500,
        ),
        activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
        turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
      ),
      // Audio transcription
      inputAudioTranscription: AudioTranscriptionConfig(),
      outputAudioTranscription: AudioTranscriptionConfig(),
      // Session resumption
      sessionResumption: SessionResumptionConfig(
        handle: null, // New session
        transparent: true,
      ),
      // Context window compression for long conversations
      contextWindowCompression: ContextWindowCompressionConfig(
        triggerTokens: '10000',
        slidingWindow: SlidingWindow(targetTokens: '5000'),
      ),
      // Proactivity config
      proactivity: ProactivityConfig(proactiveAudio: true),
    ),
  );

  // Demonstrate various features
  await _demonstrateFeatures(session);

  await Future.delayed(Duration(seconds: 5));
  await session.close();
  print('');
  print('👋 Session closed');
  print('');
  print('📚 Summary of features demonstrated:');
  print('   ✓ Basic text input/output');
  print('   ✓ Function calling');
  print('   ✓ Realtime audio input');
  print('   ✓ Realtime video input');
  print('   ✓ Audio transcription');
  print('   ✓ Session resumption');
  print('   ✓ Context window compression');
  print('   ✓ Voice activity detection');
}

Future<void> _demonstrateFeatures(LiveSession session) async {
  // 1. Basic text input
  print('');
  print('📍 Feature 1: Basic Text Input');
  print('-' * 40);
  print('💬 User: Hello, how are you?');
  session.sendText('Hello, how are you?');
  await Future.delayed(Duration(seconds: 3));

  // 2. Function calling
  print('');
  print('📍 Feature 2: Function Calling');
  print('-' * 40);
  print('💬 User: What\'s the weather in New York?');
  session.sendText('What\'s the weather in New York?');
  await Future.delayed(Duration(seconds: 3));

  // 3. Client content with multiple turns
  print('');
  print('📍 Feature 3: Multi-turn Client Content');
  print('-' * 40);
  print('💬 User: [Multi-turn context]');
  session.sendClientContent(
    turns: [
      Content(
        role: 'user',
        parts: [Part(text: 'My name is John.')],
      ),
      Content(
        role: 'model',
        parts: [Part(text: 'Hello John! Nice to meet you.')],
      ),
      Content(
        role: 'user',
        parts: [Part(text: 'What\'s my name?')],
      ),
    ],
    turnComplete: true,
  );
  await Future.delayed(Duration(seconds: 3));

  // 4. Realtime audio input
  print('');
  print('📍 Feature 4: Realtime Audio Input');
  print('-' * 40);
  print('🎙️ Sending audio chunks...');
  for (int i = 0; i < 3; i++) {
    final audioChunk = List<int>.generate(320, (index) => index % 256);
    session.sendAudio(audioChunk);
    print('   🔊 Audio chunk ${i + 1}/3');
    await Future.delayed(Duration(milliseconds: 100));
  }
  session.sendAudioStreamEnd();
  print('   🔇 Audio stream ended');
  await Future.delayed(Duration(seconds: 2));

  // 5. Realtime video input
  print('');
  print('📍 Feature 5: Realtime Video Input');
  print('-' * 40);
  print('📹 Sending video frames...');
  for (int i = 0; i < 2; i++) {
    final frame = List<int>.generate(1000, (index) => index % 256);
    session.sendVideo(frame);
    print('   📸 Video frame ${i + 1}/2');
    await Future.delayed(Duration(milliseconds: 500));
  }
  await Future.delayed(Duration(seconds: 2));

  // 6. Realtime text input
  print('');
  print('📍 Feature 6: Realtime Text Input');
  print('-' * 40);
  print('💬 Sending realtime text...');
  session.sendRealtimeText('This is a realtime text input');
  await Future.delayed(Duration(seconds: 2));

  // 7. Media chunks
  print('');
  print('📍 Feature 7: Media Chunks');
  print('-' * 40);
  print('📦 Sending media chunks...');
  session.sendMediaChunks([
    Blob(mimeType: 'audio/pcm', data: 'chunk1'),
    Blob(mimeType: 'audio/pcm', data: 'chunk2'),
  ]);
  await Future.delayed(Duration(seconds: 2));

  // 8. Combined realtime input
  print('');
  print('📍 Feature 8: Combined Realtime Input');
  print('-' * 40);
  print('🔄 Sending combined realtime input...');
  session.sendRealtimeInput(
    audio: Blob(mimeType: 'audio/pcm', data: 'audioData'),
    video: Blob(mimeType: 'image/jpeg', data: 'videoData'),
    text: 'Combined input',
  );
  await Future.delayed(Duration(seconds: 2));
}

void _handleMessage(
  LiveServerMessage message,
  LiveSession session,
  Map<String, FunctionCall> pendingCalls,
  String? sessionHandle,
) {
  // Text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Audio data
  if (message.data != null) {
    print('🔊 Audio received: ${message.data!.length} chars');
  }

  // Function calls
  if (message.toolCall != null) {
    print('🔧 Tool call received:');
    for (final call in message.toolCall!.functionCalls ?? []) {
      print('   📞 ${call.name} (id: ${call.id})');
      print('   📦 Args: ${call.args}');

      if (call.id != null) {
        _executeFunctionAndRespond(call, session);
      }
    }
  }

  // Tool call cancellation
  if (message.toolCallCancellation != null) {
    print('❌ Tool calls cancelled: ${message.toolCallCancellation!.ids}');
  }

  // Transcriptions
  if (message.serverContent?.inputTranscription != null) {
    final t = message.serverContent!.inputTranscription!;
    print('🎤 Input: ${t.text} ${t.finished == true ? '(complete)' : ''}');
  }
  if (message.serverContent?.outputTranscription != null) {
    final t = message.serverContent!.outputTranscription!;
    print('🔈 Output: ${t.text} ${t.finished == true ? '(complete)' : ''}');
  }

  // Voice activity
  if (message.voiceActivity != null) {
    print(
      '🎤 Voice activity: ${message.voiceActivity!.speechActive == true ? 'speaking' : 'silent'}',
    );
  }
  if (message.voiceActivityDetectionSignal != null) {
    final signal = message.voiceActivityDetectionSignal!;
    if (signal.start == true) print('🎙️ Speech started');
    if (signal.end == true) print('🎙️ Speech ended');
  }

  // Session resumption
  if (message.sessionResumptionUpdate != null) {
    final update = message.sessionResumptionUpdate!;
    print('🔄 Session update: ${update.newHandle}');
  }

  // Go away
  if (message.goAway != null) {
    print(
      '⏰ Server disconnecting in ${message.goAway!.timeRemaining}s: ${message.goAway!.reason}',
    );
  }

  // Usage
  if (message.usageMetadata != null) {
    final u = message.usageMetadata!;
    print(
      '📊 Tokens: ${u.totalTokenCount} (prompt: ${u.promptTokenCount}, response: ${u.responseTokenCount})',
    );
  }

  // Turn complete
  if (message.serverContent?.turnComplete == true) {
    print('✅ Turn complete');
  }
}

void _executeFunctionAndRespond(FunctionCall call, LiveSession session) {
  Map<String, dynamic> result;

  switch (call.name) {
    case 'get_weather':
      result = {
        'location': call.args?['location'] ?? 'Unknown',
        'temperature': 22,
        'unit': 'celsius',
        'condition': 'sunny',
      };
      print('   🌤️ Executed get_weather');
      break;
    case 'get_time':
      result = {
        'timezone': call.args?['timezone'] ?? 'UTC',
        'time': DateTime.now().toIso8601String(),
      };
      print('   🕐 Executed get_time');
      break;
    default:
      result = {'error': 'Unknown function: ${call.name}'};
  }

  session.sendFunctionResponse(
    id: call.id!,
    name: call.name!,
    response: result,
  );
  print('   📤 Sent function response');
}
