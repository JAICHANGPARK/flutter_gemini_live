import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:gemini_live/src/client/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthTokensService', () {
    test('creates ephemeral token with constraints and locks', () async {
      late Uri requestedUri;
      late Map<String, dynamic> requestPayload;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        requestPayload = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'name': 'auth_tokens/sample-token-abc-123',
            'expireTime': '2026-10-01T21:00:00Z',
            'newSessionExpireTime': '2026-10-01T20:41:00Z',
            'uses': 3,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        apiKey: 'master-api-key',
        httpClient: mockClient,
      );
      final service = AuthTokensService(apiClient);

      final token = await service.create(
        CreateAuthTokenConfig(
          uses: 3,
          expireTime: '2026-10-01T21:00:00Z',
          newSessionExpireTime: '2026-10-01T20:41:00Z',
          liveConnectConstraints: LiveConnectConstraints(
            model: 'gemini-2.0-flash-exp',
            config: GenerationConfig(
              responseModalities: [Modality.AUDIO],
              temperature: 0.7,
            ),
          ),
          lockAdditionalFields: ['temperature', 'topK'],
        ),
      );

      expect(token.name, 'auth_tokens/sample-token-abc-123');
      expect(token.uses, 3);
      expect(token.expireTime, '2026-10-01T21:00:00Z');

      // Check request details
      expect(requestedUri.path, '/v1alpha/authTokens');
      expect(requestedUri.queryParameters['key'], 'master-api-key');

      expect(requestPayload['uses'], 3);
      expect(requestPayload['expireTime'], '2026-10-01T21:00:00Z');
      expect(
        requestPayload['bidiGenerateContentSetup']['model'],
        'models/gemini-2.0-flash-exp',
      );
      expect(
        requestPayload['bidiGenerateContentSetup']['generationConfig']
            ['temperature'],
        0.7,
      );

      // Verify field mask includes bidiSetup fields and locked additional fields mapped properly
      final fieldMask = requestPayload['fieldMask'] as String;
      expect(fieldMask, contains('model'));
      expect(fieldMask, contains('generationConfig.temperature'));
      expect(fieldMask, contains('generationConfig.topK'));
    });

    test('GoogleGenAI exposes authTokens service', () {
      final ai = GoogleGenAI(apiKey: 'key');
      expect(ai.authTokens, isNotNull);
    });
  });
}
