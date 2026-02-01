import 'dart:io';
import 'package:gemini_live/gemini_live.dart';

/// Example: Function Calling with Live API
///
/// This example demonstrates how to use function calling (tool calling)
/// with the Gemini Live API.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  // Track function calls that need responses
  final pendingFunctionCalls = <String, FunctionCall>{};

  // Will hold the session once connected
  late final LiveSession session;

  // Connect to Live API with tools enabled
  session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-live-2.5-flash-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Live API');
        },
        onMessage: (message) {
          _handleMessage(message, session, pendingFunctionCalls);
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed');
        },
      ),
      tools: [
        // Define tools that the model can call
        // In a real implementation, you would define FunctionDeclaration tools
        Tool(),
      ],
      config: GenerationConfig(
        temperature: 0.7,
        responseModalities: [Modality.TEXT],
      ),
    ),
  );

  // Send a query that might trigger function calling
  print('💬 Sending: What\'s the weather in New York?');
  session.sendText('What\'s the weather in New York?');

  // Keep connection alive
  await Future.delayed(Duration(seconds: 30));

  await session.close();
  print('👋 Session closed');
}

void _handleMessage(
  LiveServerMessage message,
  LiveSession session,
  Map<String, FunctionCall> pendingCalls,
) {
  // Handle regular text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Handle tool calls
  if (message.toolCall != null) {
    print('🔧 Tool call received!');

    for (final call in message.toolCall!.functionCalls ?? []) {
      print('  📞 Function: ${call.name} (id: ${call.id})');
      print('  📦 Args: ${call.args}');

      // Store the pending call
      if (call.id != null) {
        pendingCalls[call.id!] = call;

        // Execute the function and send response
        _executeFunctionAndRespond(call, session);
      }
    }
  }

  // Handle tool call cancellation
  if (message.toolCallCancellation != null) {
    print('❌ Tool calls cancelled: ${message.toolCallCancellation!.ids}');

    // Remove cancelled calls from pending
    for (final id in message.toolCallCancellation!.ids ?? []) {
      pendingCalls.remove(id);
    }
  }

  // Handle usage metadata
  if (message.usageMetadata != null) {
    print('📊 Token usage: ${message.usageMetadata!.totalTokenCount}');
  }
}

void _executeFunctionAndRespond(FunctionCall call, LiveSession session) {
  // Simulate function execution
  // In a real app, you would call your actual functions here
  Map<String, dynamic> result;

  switch (call.name) {
    case 'get_weather':
      result = {
        'location': call.args?['location'] ?? 'Unknown',
        'temperature': 22,
        'unit': 'celsius',
        'condition': 'sunny',
      };
      break;
    case 'get_time':
      result = {
        'timezone': call.args?['timezone'] ?? 'UTC',
        'time': DateTime.now().toIso8601String(),
      };
      break;
    default:
      result = {'error': 'Unknown function: ${call.name}'};
  }

  // Send the function response back to the model
  print('📤 Sending function response for ${call.name}');
  session.sendFunctionResponse(
    id: call.id!,
    name: call.name!,
    response: result,
  );
}
