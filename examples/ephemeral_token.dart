import 'dart:io' show Platform;

import 'package:gemini_live/gemini_live.dart';

/// Example: Connect to Live API with an Ephemeral Token
///
/// This example demonstrates the client-side connection flow:
/// 1. Backend provisions an ephemeral token (`auth_tokens/...`).
/// 2. Client receives the token and uses it as `apiKey`.
/// 3. Client connects to Live API with `apiVersion: 'v1alpha'`.
void main() async {
  final token = Platform.environment['GEMINI_EPHEMERAL_TOKEN'];
  if (token == null || token.isEmpty) {
    print('❌ GEMINI_EPHEMERAL_TOKEN is not set.');
    print(
      'Set it first: export GEMINI_EPHEMERAL_TOKEN="auth_tokens/your_token"',
    );
    return;
  }

  final genAI = GoogleGenAI(apiKey: token, apiVersion: 'v1alpha');

  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-live-2.5-flash-preview',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('✅ Connected with ephemeral token'),
        onMessage: (message) {
          if (message.text != null) {
            print('🤖 ${message.text}');
          }
          if (message.serverContent?.turnComplete == true) {
            print('✅ Turn complete');
          }
        },
        onError: (error, stack) => print('❌ Error: $error'),
        onClose: (code, reason) =>
            print('🔒 Closed: code=$code, reason=$reason'),
      ),
    ),
  );

  session.sendText('Hello! Reply briefly so I can verify token auth.');
  await Future.delayed(const Duration(seconds: 8));
  await session.close();
  genAI.close();
}
