import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Voices Models', () {
    test('VoiceConfig and SpeechConfig factories and serialization', () {
      final configByName = VoiceConfig.fromVoiceName('Charon');
      expect(configByName.prebuiltVoiceConfig?.voiceName, 'Charon');
      expect(configByName.voice, 'Charon');

      final jsonByName = configByName.toJson();
      expect(jsonByName['voice'], 'Charon');
      expect(jsonByName['prebuilt_voice_config']['voice_name'], 'Charon');

      final parsedByName = VoiceConfig.fromJson(jsonByName);
      expect(parsedByName.voice, 'Charon');
      expect(parsedByName.prebuiltVoiceConfig?.voiceName, 'Charon');

      final configById = VoiceConfig.fromVoiceId('voice_custom_987');
      expect(configById.voice, 'voice_custom_987');
      final jsonById = configById.toJson();
      expect(jsonById['voice'], 'voice_custom_987');

      final promptedVoice = PromptedVoice(
        input: 'A warm, encouraging mentor with a calm demeanor',
      );
      final configPrompted = VoiceConfig(
        promptedVoiceConfig: promptedVoice,
        voice: 'voice_prompted_123',
      );
      final jsonPrompted = configPrompted.toJson();
      expect(
        jsonPrompted['prompted_voice_config']['input'],
        'A warm, encouraging mentor with a calm demeanor',
      );
      expect(jsonPrompted['voice'], 'voice_prompted_123');

      final parsedPrompted = VoiceConfig.fromJson(jsonPrompted);
      expect(
        parsedPrompted.promptedVoiceConfig?.input,
        'A warm, encouraging mentor with a calm demeanor',
      );

      final speechConfig = SpeechConfig.fromVoice(
        'Fenrir',
        languageCode: 'en-US',
      );
      expect(speechConfig.voice, 'Fenrir');
      expect(speechConfig.languageCode, 'en-US');
      expect(speechConfig.voiceConfig?.prebuiltVoiceConfig?.voiceName, 'Fenrir');

      final speechJson = speechConfig.toJson();
      expect(speechJson['voice'], 'Fenrir');
      expect(speechJson['language_code'], 'en-US');

      final parsedSpeech = SpeechConfig.fromJson(speechJson);
      expect(parsedSpeech.voice, 'Fenrir');
      expect(parsedSpeech.languageCode, 'en-US');
    });

    test('VoiceResource round-trip serialization', () {
      final voice = VoiceResource(
        id: 'voice_abc123',
        key: 'voicekey_def456',
        type: VoiceType.prompted,
        displayName: 'Mentor Voice',
        description: 'Warm and empathetic mentor voice',
        accent: 'American',
        gender: 'female',
        languageCode: 'en-US',
        persona: 'Mentor',
        pitch: VoicePitch.medium,
        context: 'Conversational',
        regionCode: 'US',
        model: 'voice-design-001',
        expireTime: '2026-10-01T00:00:00Z',
        prompted: PromptedVoice(input: 'Calm voice'),
      );

      final json = voice.toJson();
      expect(json['id'], 'voice_abc123');
      expect(json['key'], 'voicekey_def456');
      expect(json['type'], 'prompted');
      expect(json['pitch'], 'medium');
      expect(json['display_name'], 'Mentor Voice');

      final deserialized = VoiceResource.fromJson(json);
      expect(deserialized.id, 'voice_abc123');
      expect(deserialized.key, 'voicekey_def456');
      expect(deserialized.type, VoiceType.prompted);
      expect(deserialized.pitch, VoicePitch.medium);
      expect(deserialized.prompted?.input, 'Calm voice');
    });

    test('CreateVoiceRequest factories and round-trip serialization', () {
      final reqPrompted = CreateVoiceRequest.prompted(
        prompt: 'Authoritative yet gentle instructor',
        displayName: 'Instructor Voice',
        pitch: VoicePitch.low,
        gender: 'neutral',
        store: true,
      );
      final jsonPrompted = reqPrompted.toJson();
      expect(jsonPrompted['type'], 'prompted');
      expect(jsonPrompted['prompted']['input'], 'Authoritative yet gentle instructor');
      expect(jsonPrompted['pitch'], 'low');
      expect(jsonPrompted['store'], true);

      final deserializedPrompted = CreateVoiceRequest.fromJson(jsonPrompted);
      expect(deserializedPrompted.type, VoiceType.prompted);
      expect(deserializedPrompted.prompted?.input, 'Authoritative yet gentle instructor');

      final reqReplicated = CreateVoiceRequest.replicated(
        sourceAudio: VoiceAudioData(data: 'c291cmNl', mimeType: 'audio/wav'),
        consentAudio: VoiceAudioData(data: 'Y29uc2VudA==', mimeType: 'audio/wav'),
        displayName: 'Cloned Voice',
        store: false,
      );
      final jsonReplicated = reqReplicated.toJson();
      expect(jsonReplicated['type'], 'replicated');
      expect(jsonReplicated['replicated']['source_audio']['data'], 'c291cmNl');
      expect(jsonReplicated['replicated']['consent_audio']['data'], 'Y29uc2VudA==');
      expect(jsonReplicated['store'], false);

      final deserializedReplicated = CreateVoiceRequest.fromJson(jsonReplicated);
      expect(deserializedReplicated.type, VoiceType.replicated);
      expect(deserializedReplicated.replicated?.sourceAudio?.data, 'c291cmNl');
      expect(deserializedReplicated.replicated?.consentAudio?.data, 'Y29uc2VudA==');
    });

    test('ListVoicesResponse and DeleteVoiceResponse serialization', () {
      final listResp = ListVoicesResponse(
        voices: [
          VoiceResource(id: 'Puck', type: VoiceType.prebuilt, displayName: 'Puck'),
          VoiceResource(id: 'voice_123', type: VoiceType.prompted, displayName: 'Custom 1'),
        ],
        nextPageToken: 'token_page_2',
      );
      final listJson = listResp.toJson();
      expect((listJson['voices'] as List).length, 2);
      expect(listJson['next_page_token'], 'token_page_2');

      final deserializedList = ListVoicesResponse.fromJson(listJson);
      expect(deserializedList.voices?.length, 2);
      expect(deserializedList.nextPageToken, 'token_page_2');

      final deleteResp = DeleteVoiceResponse(message: 'Voice deleted successfully');
      final deleteJson = deleteResp.toJson();
      expect(deleteJson['message'], 'Voice deleted successfully');

      final deserializedDelete = DeleteVoiceResponse.fromJson(deleteJson);
      expect(deserializedDelete.message, 'Voice deleted successfully');
    });
  });

  group('GeminiVoicesService', () {
    test('listVoices sends correct query parameters and parses response', () async {
      late Uri capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'voices': [
              {
                'id': 'Puck',
                'type': 'prebuilt',
                'display_name': 'Puck',
                'gender': 'neutral',
              },
              {
                'id': 'voice_custom_1',
                'type': 'prompted',
                'display_name': 'My Prompted Voice',
              },
            ],
            'next_page_token': 'page2_token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiVoicesService(
        apiKey: 'test-api-key',
        apiVersion: 'v1alpha',
        httpClient: mockClient,
      );

      final response = await service.listVoices(
        pageSize: 10,
        pageToken: 'token123',
        search: 'mentor',
        type: VoiceType.prompted,
        gender: 'female',
        pitch: VoicePitch.high,
        languageCode: 'en-US',
        accent: 'American',
        persona: 'Educator',
        context: 'Audiobook',
        regionCode: 'US',
      );

      expect(capturedUri.path, '/v1alpha/voices');
      expect(capturedUri.queryParameters['key'], 'test-api-key');
      expect(capturedUri.queryParameters['pageSize'], '10');
      expect(capturedUri.queryParameters['pageToken'], 'token123');
      expect(capturedUri.queryParameters['search'], 'mentor');
      expect(capturedUri.queryParameters['type'], 'prompted');
      expect(capturedUri.queryParameters['gender'], 'female');
      expect(capturedUri.queryParameters['pitch'], 'high');
      expect(capturedUri.queryParameters['languageCode'], 'en-US');
      expect(capturedUri.queryParameters['accent'], 'American');
      expect(capturedUri.queryParameters['persona'], 'Educator');
      expect(capturedUri.queryParameters['context'], 'Audiobook');
      expect(capturedUri.queryParameters['regionCode'], 'US');

      expect(response.voices?.length, 2);
      expect(response.voices?.first.id, 'Puck');
      expect(response.voices?.first.type, VoiceType.prebuilt);
      expect(response.nextPageToken, 'page2_token');

      service.close();
    });

    test('createVoice posts payload and returns created VoiceResource', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1alpha/voices');
        expect(request.url.queryParameters['key'], 'test-api-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'prompted');
        expect(body['prompted']['input'], 'Clear articulate narrator');

        return http.Response(
          jsonEncode({
            'id': 'voice_narrator_001',
            'type': 'prompted',
            'display_name': 'Narrator 1',
            'model': 'voice-design-001',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiVoicesService(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );

      final created = await service.createVoice(
        CreateVoiceRequest.prompted(prompt: 'Clear articulate narrator'),
      );

      expect(created.id, 'voice_narrator_001');
      expect(created.type, VoiceType.prompted);
      expect(created.displayName, 'Narrator 1');

      service.close();
    });

    test('getVoice retrieves voice by ID handling voices/ prefix', () async {
      late String capturedPath;
      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'id': 'voice_abc999',
            'type': 'replicated',
            'display_name': 'Replicated Voice',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiVoicesService(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );

      final voice1 = await service.getVoice('voices/voice_abc999');
      expect(capturedPath, '/v1alpha/voices/voice_abc999');
      expect(voice1.id, 'voice_abc999');

      final voice2 = await service.getVoice('voice_abc999');
      expect(capturedPath, '/v1alpha/voices/voice_abc999');
      expect(voice2.id, 'voice_abc999');

      service.close();
    });

    test('deleteVoice deletes voice by ID handling voices/ prefix', () async {
      late String capturedPath;
      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        expect(request.method, 'DELETE');
        return http.Response(
          jsonEncode({'message': 'Deleted'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiVoicesService(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );

      final result = await service.deleteVoice('voices/voice_to_delete');
      expect(capturedPath, '/v1alpha/voices/voice_to_delete');
      expect(result.message, 'Deleted');

      service.close();
    });

    test('GoogleGenAI initializes voices service correctly', () {
      final genAI = GoogleGenAI(apiKey: 'key_test');
      expect(genAI.voices, isA<GeminiVoicesService>());
      expect(genAI.live, isA<LiveService>());
      genAI.close();
    });
  });
}
