import 'dart:io' show Platform;
import 'package:gemini_live/gemini_live.dart';

/// Example: Session Resumption
///
/// This example demonstrates how to resume a previous Live API session
/// using session resumption configuration.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  // Try to load a previous session handle (if exists)
  String? previousSessionHandle = _loadPreviousSessionHandle();

  print(
    '🔄 Connecting${previousSessionHandle != null ? ' with previous session' : ''}...',
  );

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  // Track the session handle for resumption
  String? currentSessionHandle;

  final session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-live-2.5-flash-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Live API');
        },
        onMessage: (message) {
          currentSessionHandle = _handleMessage(message, currentSessionHandle);
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed: code=$code, reason=$reason');

          // Save session handle for resumption
          if (currentSessionHandle != null) {
            _saveSessionHandle(currentSessionHandle);
            print('💾 Session handle saved: $currentSessionHandle');
          }
        },
      ),
      config: GenerationConfig(
        temperature: 0.7,
        responseModalities: [Modality.TEXT],
      ),
      // Configure session resumption
      sessionResumption: SessionResumptionConfig(
        handle: previousSessionHandle, // null for new session
      ),
      // Configure context window compression to manage long sessions
      contextWindowCompression: ContextWindowCompressionConfig(
        triggerTokens: '10000', // Compress when exceeding 10k tokens
        slidingWindow: SlidingWindow(
          targetTokens: '5000', // Keep last 5k tokens
        ),
      ),
    ),
  );

  // Continue conversation
  if (previousSessionHandle != null) {
    print('💬 Continuing previous conversation...');
    session.sendText('Remember what we were discussing earlier?');
  } else {
    print('💬 Starting new conversation...');
    session.sendText(
      'Hello, let\'s have a conversation that I might resume later.',
    );
  }

  // Keep connection alive
  await Future.delayed(Duration(seconds: 30));

  await session.close();
  print('👋 Session closed');

  print('\n💡 To resume this session later, run this example again.');
  print('   The session handle will be automatically saved and restored.');
}

String? _handleMessage(LiveServerMessage message, String? sessionHandle) {
  // Handle text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Handle session resumption update
  if (message.sessionResumptionUpdate != null) {
    final update = message.sessionResumptionUpdate!;
    print('🔄 Session resumption update:');
    print('   New handle: ${update.newHandle}');
    print('   Resumable: ${update.resumable}');
    print(
      '   Last consumed message index: ${update.lastConsumedClientMessageIndex}',
    );

    // Update the session handle for saving
    if (update.newHandle != null) {
      print(
        '   💾 Save this handle for future resumption: ${update.newHandle}',
      );
      sessionHandle = update.newHandle;
    }
  }

  // Handle go away message (server will disconnect soon)
  if (message.goAway != null) {
    final goAway = message.goAway!;
    print('⏰ Server will disconnect soon!');
    print('   Reason: ${goAway.reason}');
    print('   Time remaining: ${goAway.timeRemaining} seconds');
    print('   💡 Save session handle now if you want to resume later!');
  }

  // Handle usage metadata
  if (message.usageMetadata != null) {
    final usage = message.usageMetadata!;
    print(
      '📊 Token usage: ${usage.totalTokenCount} ' +
          '(prompt: ${usage.promptTokenCount}, response: ${usage.responseTokenCount})',
    );
  }

  return sessionHandle;
}

String? _loadPreviousSessionHandle() {
  // In a real app, load from secure storage, database, or file
  // For this example, we check environment variable
  final handle = Platform.environment['GEMINI_SESSION_HANDLE'];
  if (handle != null && handle.isNotEmpty) {
    print('📂 Loaded previous session handle: $handle');
    return handle;
  }
  return null;
}

void _saveSessionHandle(String handle) {
  // In a real app, save to secure storage, database, or file
  // For this example, we just print instructions
  print('💾 To resume this session later, set this environment variable:');
  print('   export GEMINI_SESSION_HANDLE="$handle"');
  print('   Then run this example again.');
}
