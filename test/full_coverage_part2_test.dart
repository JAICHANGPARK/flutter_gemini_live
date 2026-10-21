// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/compat/firebase_ai.dart';
import 'package:gemini_live/gemini_live.dart' as core;
import 'package:gemini_live/src/client/api_client.dart';
import 'package:gemini_live/src/compat/firebase_ai/content.dart';
import 'package:gemini_live/src/compat/firebase_ai/converters.dart';
import 'package:gemini_live/src/compat/firebase_ai/live_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.channel);

  final _FakeChannel channel;
  final List<dynamic> sent = [];
  bool isClosed = false;

  @override
  void add(dynamic data) {
    if (isClosed || channel.closeCode != null) return;
    sent.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    isClosed = true;
    channel.closeCode ??= closeCode ?? 1000;
    channel.closeReason ??= closeReason;
    await channel.incoming.close();
  }

  @override
  Future<void> get done => Future.value();
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel() {
    _sink = _FakeSink(this);
  }

  final incoming = StreamController<dynamic>.broadcast(sync: true);
  late final _FakeSink _sink;

  @override
  int? closeCode;

  @override
  String? closeReason;

  List<dynamic> get sent => _sink.sent;

  void serverSend(dynamic data) => incoming.add(data);

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Part 2 - AuthTokensService Full Coverage', () {
    test('covers all LiveConnectConstraints and lockAdditionalFields branches', () async {
      late Map<String, dynamic> requestPayload;

      final mockClient = MockClient((request) async {
        requestPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'name': 'auth_tokens/test-token-123',
            'expireTime': '2026-10-01T21:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(apiKey: 'key', httpClient: mockClient);
      final service = core.AuthTokensService(apiClient);

      // Test 1: model with 'models/' prefix, null config + translationConfig, all other options
      final token = await service.create(
        core.CreateAuthTokenConfig(
          liveConnectConstraints: core.LiveConnectConstraints(
            model: 'models/gemini-2.0-flash-exp',
            translationConfig: core.TranslationConfig(targetLanguageCode: 'es'),
            systemInstruction: core.Content(parts: [core.Part(text: 'prompt')]),
            tools: [core.Tool(functionDeclarations: [core.FunctionDeclaration(name: 'f')])],
            realtimeInputConfig: core.RealtimeInputConfig(),
            sessionResumption: core.SessionResumptionConfig(),
            contextWindowCompression: core.ContextWindowCompressionConfig(),
            inputAudioTranscription: core.AudioTranscriptionConfig(),
            outputAudioTranscription: core.AudioTranscriptionConfig(),
            proactivity: core.ProactivityConfig(),
            avatarConfig: core.AvatarConfig(),
            safetySettings: [core.SafetySetting()],
            historyConfig: core.HistoryConfig(initialHistoryInClientContent: true),
          ),
          lockAdditionalFields: ['custom_lock_field', 'temperature'],
        ),
      );

      expect(token.name, 'auth_tokens/test-token-123');
      final setup = requestPayload['bidiGenerateContentSetup'] as Map<String, dynamic>;
      expect(setup['model'], 'models/gemini-2.0-flash-exp');
      expect(setup['generationConfig']['translationConfig'], isNotNull);
      expect(setup['systemInstruction'], isNotNull);
      expect(setup['tools'], isNotNull);
      expect(setup['realtimeInputConfig'], isNotNull);
      expect(setup['sessionResumption'], isNotNull);
      expect(setup['contextWindowCompression'], isNotNull);
      expect(setup['inputAudioTranscription'], isNotNull);
      expect(setup['outputAudioTranscription'], isNotNull);
      expect(setup['proactivity'], isNotNull);
      expect(setup['avatarConfig'], isNotNull);
      expect(setup['safetySettings'], isNotNull);
      expect(setup['historyConfig'], isNotNull);

      // Verify custom field in lockAdditionalFields
      final mask = requestPayload['fieldMask'] as String;
      expect(mask.contains('custom_lock_field'), isTrue);
      expect(mask.contains('generationConfig.temperature'), isTrue);
    });
  });

  group('Part 2 - MusicService Full Coverage', () {
    test('session methods: setWeightedPrompts validation and setMusicGenerationConfig default', () async {
      final fakeChannel = _FakeChannel();
      final musicService = core.LiveMusicService(
        apiKey: 'key',
        connector: (uri, headers) async => fakeChannel,
      );

      final connectFuture = musicService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(),
        ),
      );

      await pumpEventQueue();
      fakeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final session = await connectFuture;

      expect(() => session.setWeightedPrompts([]), throwsArgumentError);

      session.setMusicGenerationConfig();
      expect(fakeChannel.sent.length, 2); // setup + config
      final decoded = jsonDecode(fakeChannel.sent.last as String);
      expect(decoded['musicGenerationConfig'], isNotNull);

      await session.close();
    });

    test('handles binary, unexpected types, and JSON parse errors in WebSocket stream', () async {
      final logs = <String>[];
      final fakeChannel = _FakeChannel();

      final receivedMessages = <core.LiveMusicServerMessage>[];
      final receivedErrors = <Object>[];

      final musicService = core.LiveMusicService(
        apiKey: 'key',
        logger: logs.add,
        connector: (uri, headers) async => fakeChannel,
      );

      final connectFuture = musicService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(
            onMessage: receivedMessages.add,
            onError: (err, st) => receivedErrors.add(err),
          ),
        ),
      );

      await pumpEventQueue();
      fakeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final session = await connectFuture;

      // 1. Binary payload (List<int>)
      final binaryPayload = utf8.encode(jsonEncode({
        'serverContent': {'audioChunks': []},
      }));
      fakeChannel.serverSend(binaryPayload);

      // 2. Unexpected type (int)
      fakeChannel.serverSend(9999);

      // 3. Invalid JSON string
      fakeChannel.serverSend('invalid json string');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(receivedMessages.length, 2); // setupComplete + serverContent
      expect(receivedErrors.length, 2); // int error + json parse error
      expect(logs.any((l) => l.contains('LiveMusic parse error')), isTrue);

      await session.close();
    });

    test('connect lifecycle: stream error, model prefixing, and connector failure', () async {
      // 1. Model without models/ prefix
      final fakeChannel = _FakeChannel();
      final musicService = core.LiveMusicService(
        apiKey: 'key',
        connector: (uri, headers) async => fakeChannel,
      );

      final connectFuture = musicService.connect(
        core.LiveMusicConnectParameters(
          model: 'lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(),
        ),
      );
      await pumpEventQueue();
      fakeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final session = await connectFuture;

      final sentSetup = jsonDecode(fakeChannel.sent.first as String);
      expect(sentSetup['setup']['model'], 'models/lyria-realtime-exp');
      await session.close();

      // 2. Stream error during connection before setup
      final errorChannel = _FakeChannel();
      Object? caughtStreamError;
      final errorService = core.LiveMusicService(
        apiKey: 'key',
        connector: (uri, headers) async => errorChannel,
      );
      final connFut = errorService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(
            onError: (err, st) => caughtStreamError = err,
          ),
        ),
      );
      final expectError = expectLater(connFut, throwsA(isA<Exception>()));
      await pumpEventQueue();
      errorChannel.incoming.addError(Exception('socket failure'));
      await expectError;
      expect(caughtStreamError, isNotNull);

      // 3. Channel done before setup completes
      final doneChannel = _FakeChannel();
      final doneService = core.LiveMusicService(
        apiKey: 'key',
        connector: (uri, headers) async => doneChannel,
      );
      final doneFut = doneService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(),
        ),
      );
      final expectDone = expectLater(doneFut, throwsStateError);
      await pumpEventQueue();
      await doneChannel.incoming.close();
      await expectDone;

      // 4. Connection established, then message dispatch, stream error, and stream done
      final liveChannel = _FakeChannel();
      Object? postConnectError;
      core.LiveMusicServerMessage? handledMessage;
      final liveService = core.LiveMusicService(
        apiKey: 'key',
        logger: (msg) {},
        connector: (uri, headers) async => liveChannel,
      );
      final liveFut = liveService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(
            onMessage: (msg) => handledMessage = msg,
            onError: (err, st) => postConnectError = err,
            onClose: (code, reason) {},
          ),
        ),
      );
      await pumpEventQueue();
      liveChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final liveSession = await liveFut;

      // server message dispatch
      liveChannel.serverSend(jsonEncode({'serverContent': {}}));
      await pumpEventQueue();
      expect(handledMessage, isNotNull);

      // trigger error after connection
      liveChannel.incoming.addError(Exception('live stream err'));
      await pumpEventQueue();
      expect(postConnectError, isNotNull);

      // trigger done after connection
      await liveChannel.incoming.close();
      await pumpEventQueue();
      await liveSession.close();

      // 5. Setup timeout
      final timeoutChannel = _FakeChannel();
      final timeoutService = core.LiveMusicService(
        apiKey: 'key',
        setupTimeout: const Duration(milliseconds: 5),
        connector: (uri, headers) async => timeoutChannel,
      );
      final timeoutFut = timeoutService.connect(
        core.LiveMusicConnectParameters(
          model: 'models/lyria-realtime-exp',
          callbacks: core.LiveMusicCallbacks(),
        ),
      );
      await expectLater(
        timeoutFut,
        throwsA(predicate((e) => e.toString().contains('Timeout waiting for setupComplete'))),
      );

      // 6. Connector throwing an exception
      final failingService = core.LiveMusicService(
        apiKey: 'key',
        connector: (uri, headers) async {
          throw StateError('Cannot resolve host');
        },
      );
      Object? rethrowError;
      await expectLater(
        () => failingService.connect(
          core.LiveMusicConnectParameters(
            model: 'models/lyria-realtime-exp',
            callbacks: core.LiveMusicCallbacks(
              onError: (err, st) => rethrowError = err,
            ),
          ),
        ),
        throwsStateError,
      );
      expect(rethrowError, isNotNull);
    });
  });

  group('Part 2 - Firebase AI Compat Full Coverage', () {
    test('Schema constructors and JSONSchema features', () {
      final arr = Schema.array(
        items: Schema.string(),
        description: 'arr desc',
        title: 'arr title',
        nullable: true,
        minItems: 1,
        maxItems: 5,
      );
      expect(arr.type, SchemaType.array);

      final b = Schema.boolean(
        description: 'bool desc',
        title: 'bool title',
        nullable: false,
      );
      expect(b.type, SchemaType.boolean);

      final numSchema = Schema.number(
        description: 'num desc',
        title: 'num title',
        nullable: false,
        format: 'float',
        minimum: 0.0,
        maximum: 100.0,
      );
      expect(numSchema.type, SchemaType.number);

      final enumStr = Schema.enumString(
        enumValues: ['A', 'B'],
        description: 'enum desc',
        title: 'enum title',
        nullable: false,
      );
      expect(enumStr.type, SchemaType.string);

      // JSONSchema full features
      final jsAnyOf = JSONSchema.anyOf(schemas: [
        JSONSchema.string(),
        JSONSchema.number(),
      ]);
      expect(jsAnyOf.type, SchemaType.anyOf);

      final jsRef = JSONSchema.ref('#/\$defs/MyType');
      expect(jsRef.type, SchemaType.ref);

      final jsObj = JSONSchema.object(
        properties: {'name': JSONSchema.string()},
        optionalProperties: ['name'],
        propertyOrdering: ['name'],
        defs: {'MyType': JSONSchema.string()},
        nullable: true,
      );
      expect(jsObj.type, SchemaType.object);

      final jsArr = JSONSchema.array(
        items: JSONSchema.string(),
        description: 'array',
        minItems: 2,
        maxItems: 4,
      );
      jsArr.items = JSONSchema.number();
      expect(jsArr.items?.type, SchemaType.number);

      final jsBool = JSONSchema.boolean(description: 'bool');
      expect(jsBool.type, SchemaType.boolean);
      final jsInt = JSONSchema.integer(minimum: 1, maximum: 10);
      expect(jsInt.type, SchemaType.integer);
      final jsNum = JSONSchema.number(minimum: 1.0, maximum: 10.0);
      expect(jsNum.type, SchemaType.number);
      final jsEnum = JSONSchema.enumString(enumValues: ['X', 'Y']);
      expect(jsEnum.type, SchemaType.string);
      final jsString = JSONSchema.string(format: 'uri');
      expect(jsString.type, SchemaType.string);

      jsObj.properties = {'foo': JSONSchema.string()};
      expect(jsObj.properties?['foo'], isNotNull);
      jsObj.anyOf = [JSONSchema.string()];
      expect(jsObj.anyOf?.length, 1);

      final json = jsObj.toJson();
      expect(json[r'$defs'], isNotNull);
      expect(json['properties'], isNotNull);
      expect(jsRef.toJson()[r'$ref'], '#/\$defs/MyType');
    });

    test('Content and Part classes full coverage', () {
      final inline = Content.inlineData('image/png', Uint8List.fromList([1, 2, 3]), mediaResolution: MediaResolution.high);
      expect(inline.parts.first, isA<InlineDataPart>());

      final multiFunc = Content.functionResponses([
        FunctionResponse('fn1', {'res': 1}, id: 'id1'),
      ]);
      expect(multiFunc.parts.length, 1);

      final unknown = UnknownPart({'customKey': 'customVal'});
      final unknownJson = unknown.toJson() as Map<String, dynamic>;
      expect(unknownJson['customKey'], 'customVal');

      final inlinePart = InlineDataPart('audio/pcm', Uint8List.fromList([10, 20]), mediaResolution: MediaResolution.low, willContinue: true);
      final chunkJson = inlinePart.toMediaChunkJson() as Map<String, dynamic>;
      expect(chunkJson['willContinue'], true);

      final funcCall = FunctionCall('callMe', {'a': 1}, id: 'call_1');
      final callJson = funcCall.toJson() as Map<String, dynamic>;
      expect(callJson['functionCall']['id'], 'call_1');

      final fileData = FileData('application/pdf', 'gs://bucket/file.pdf', mediaResolution: MediaResolution.medium);
      final fileJson = fileData.toJson() as Map<String, dynamic>;
      expect(fileJson['file_data']['file_uri'], 'gs://bucket/file.pdf');

      final execCode = ExecutableCodePart(language: CodeLanguage.python, code: 'print(42)');
      final execJson = execCode.toJson() as Map<String, dynamic>;
      expect(execJson['executableCode']['language'], 'PYTHON');

      final resultPart = CodeExecutionResultPart(outcome: Outcome.ok, output: '42');
      final resJson = resultPart.toJson() as Map<String, dynamic>;
      expect(resJson['codeExecutionResult']['outcome'], 'OUTCOME_OK');

      expect(CodeLanguage.python.toJson(), 'PYTHON');
      expect(CodeLanguage.parseValue('PYTHON'), CodeLanguage.python);
      expect(CodeLanguage.parseValue('OTHER'), CodeLanguage.unspecified);

      expect(Outcome.ok.toJson(), 'OUTCOME_OK');
      expect(Outcome.parseValue('OUTCOME_OK'), Outcome.ok);
      expect(Outcome.parseValue('OUTCOME_FAILED'), Outcome.failed);
      expect(Outcome.parseValue('OUTCOME_DEADLINE_EXCEEDED'), Outcome.deadlineExceeded);
      expect(Outcome.parseValue('OTHER'), Outcome.unspecified);
    });

    test('Converters full coverage', () {
      final inline = InlineDataPart('audio/pcm', Uint8List.fromList([1]));
      final fnCall = FunctionCall('f', {}, id: 'id');
      final fnRes = FunctionResponse('f', {}, id: 'id');
      final fileData = FileData('text/plain', 'https://example.com/t.txt');
      final code = ExecutableCodePart(language: CodeLanguage.python, code: 'x = 1');
      final codeRes = CodeExecutionResultPart(outcome: Outcome.ok, output: 'ok');
      final unk = UnknownPart({'raw': 'val'});

      expect(toCorePart(inline).inlineData, isNotNull);
      expect(toCorePart(fnCall).functionCall, isNotNull);
      expect(toCorePart(fnRes).functionResponse, isNotNull);
      expect(toCorePart(fileData).fileData, isNotNull);
      expect(toCorePart(code).executableCode, isNotNull);
      expect(toCorePart(codeRes).codeExecutionResult, isNotNull);
      expect(toCorePart(unk), isNotNull);

      expect(toCoreMediaResolution(MediaResolution.unspecified), core.MediaResolution.MEDIA_RESOLUTION_UNSPECIFIED);
      expect(toCoreMediaResolution(MediaResolution.ultraHigh), core.MediaResolution.MEDIA_RESOLUTION_UNSPECIFIED);

      final speech = SpeechConfig.multiSpeaker(
        multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig(
          speakerVoiceConfigs: [
            SpeakerVoiceConfig(speaker: 'S1', voiceName: 'Puck'),
          ],
        ),
      );
      final coreSpeech = toCoreSpeechConfig(speech);
      expect(coreSpeech.multiSpeakerVoiceConfig, isNotNull);

      // fromCorePart
      expect(fromCorePart(core.Part(functionCall: core.FunctionCall(name: 'f', args: {}))), isA<FunctionCall>());
      expect(fromCorePart(core.Part(functionResponse: core.FunctionResponse(name: 'f', response: {}))), isA<FunctionResponse>());
      expect(fromCorePart(core.Part(fileData: core.FileData(mimeType: 'text/plain', fileUri: 'uri'))), isA<FileData>());
      expect(fromCorePart(core.Part(executableCode: core.ExecutableCode(language: 'PYTHON', code: 'x'))), isA<ExecutableCodePart>());
      expect(fromCorePart(core.Part(codeExecutionResult: core.CodeExecutionResult(outcome: 'OUTCOME_OK', output: 'ok'))), isA<CodeExecutionResultPart>());
      expect(fromCorePart(core.Part()), isA<UnknownPart>());
    });

    test('LiveApi types and exceptions coverage', () {
      expect(ResponseModalities.audio.toJson(), 'AUDIO');
      expect(MediaResolution.parseValue('MEDIA_RESOLUTION_LOW'), MediaResolution.low);
      expect(MediaResolution.parseValue('MEDIA_RESOLUTION_MEDIUM'), MediaResolution.medium);
      expect(MediaResolution.parseValue('MEDIA_RESOLUTION_HIGH'), MediaResolution.high);
      expect(MediaResolution.parseValue('MEDIA_RESOLUTION_ULTRA_HIGH'), MediaResolution.ultraHigh);
      expect(MediaResolution.parseValue('UNKNOWN'), MediaResolution.unspecified);

      final disabledVad = ActivityDetectionConfig.disabled();
      expect(disabledVad.disabled, isTrue);

      final transcriptionConfig = AudioTranscriptionConfig();
      expect(transcriptionConfig.toJson(), isEmpty);

      // Exceptions toString
      expect(FirebaseAIException('err').toString(), contains('FirebaseAIException: err'));
      expect(ServerException('srv').toString(), 'srv');
      expect(InvalidApiKey('inv').toString(), 'inv');
      expect(UnsupportedUserLocation().message, contains('User location is not supported'));
      expect(ServiceApiNotEnabled('proj1').toString(), contains('proj1'));
      expect(QuotaExceeded('quota').toString(), 'quota');
      expect(FirebaseAISdkException('sdk').toString(), 'sdk');
    });

    test('Tool classes coverage', () {
      final codeTool = Tool.codeExecution();
      expect(codeTool.toJson()['codeExecution'], isNotNull);

      final urlTool = Tool.urlContext();
      expect(urlTool.toJson()['urlContext'], isNotNull);

      final mapsTool = Tool.googleMaps();
      expect(mapsTool.toJson()['googleMaps'], isNotNull);

      final autoFn = AutoFunctionDeclaration(
        name: 'autoFn',
        description: 'desc',
        parameters: {'param': JSONSchema.string()},
        callable: (args) async => {'result': 'ok'},
      );
      final fnTool = Tool.functionDeclarations([autoFn]);
      expect(fnTool.autoFunctionDeclarations.length, 1);
      final fnJson = fnTool.toJson()['functionDeclarations'] as List;
      expect(fnJson.first['parametersJsonSchema'], isNotNull);
    });

    test('LiveSession edge cases: penalty warning, closed exception toString, realtime activity, media chunks', () async {
      final fakeChannel = _FakeChannel();
      final ai = FirebaseAI.forTesting(
        core.LiveService(
          apiKey: 'key',
          connector: (uri, headers) async => fakeChannel,
        ),
      );

      final model = ai.liveGenerativeModel(
        model: 'gemini-2.0-flash-exp',
        liveGenerationConfig: LiveGenerationConfig(
          presencePenalty: 0.5,
          frequencyPenalty: 0.5,
        ),
      );

      final connectFuture = model.connect();
      await pumpEventQueue();
      fakeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final session = await connectFuture;

      // Send realtime activity
      await session.sendStartActivityRealtime();
      await session.sendStopActivityRealtime();

      // Send media chunks
      await session.sendMediaChunks(mediaChunks: [
        InlineDataPart('video/mp4', Uint8List.fromList([1, 2])),
        InlineDataPart('application/octet-stream', Uint8List.fromList([3, 4])),
      ]);

      // Stream error in media stream
      final errorStream = Stream<InlineDataPart>.error(Exception('stream failure'));
      await expectLater(
        () => session.sendMediaStream(errorStream),
        throwsA(isA<FirebaseAISdkException>()),
      );

      // Close session
      await session.close();

      // Receive after close throws on stream
      expect(session.receive(), emitsError(isA<LiveWebSocketClosedException>()));

      // Closed exception custom messages
      final deadlineEx = LiveWebSocketClosedException('DEADLINE_EXCEEDED');
      expect(deadlineEx.toString(), contains('expired'));

      final resourceEx = LiveWebSocketClosedException('RESOURCE_EXHAUSTED');
      expect(resourceEx.toString(), contains('maximum number of concurrent sessions'));

      final genericEx = LiveWebSocketClosedException('normal close');
      expect(genericEx.toString(), 'normal close');
    });

    test('LiveSession error forwarding and resumeSession', () async {
      var activeChannel = _FakeChannel();
      final ai = FirebaseAI.forTesting(
        core.LiveService(
          apiKey: 'key',
          connector: (uri, headers) async => activeChannel,
        ),
      );

      final model = ai.liveGenerativeModel(
        model: 'gemini-2.0-flash-exp',
      );

      final connectFuture = model.connect();
      await pumpEventQueue();
      activeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      final session = await connectFuture;

      Object? streamErr;
      final sub = session.receive().listen(
        (_) {},
        onError: (err) => streamErr = err,
      );

      activeChannel.incoming.addError(Exception('socket failed'));
      await pumpEventQueue();
      expect(streamErr, isNotNull);

      // Resume session with new channel
      activeChannel = _FakeChannel();
      final resumeFuture = session.resumeSession();
      await pumpEventQueue();
      activeChannel.serverSend(jsonEncode({'setupComplete': {}}));
      await resumeFuture;

      await sub.cancel();
      await session.close();
    });

    test('remaining Schema, Content, and Tool edge cases', () {
      // 1. Tool.googleSearch().autoFunctionDeclarations
      final searchTool = Tool.googleSearch();
      expect(searchTool.autoFunctionDeclarations, isEmpty);

      // 2. InlineDataPart.toJson with mediaResolution
      final inline = InlineDataPart('image/png', Uint8List.fromList([1, 2]), mediaResolution: MediaResolution.low);
      final inlineJson = inline.toJson() as Map<String, dynamic>;
      expect(inlineJson['mediaResolution'], isNotNull);

      // 3. FunctionResponse.toJson with and without id
      final fnResWithId = FunctionResponse('fn', {'val': 123}, id: 'fn_id_1');
      final fnJson1 = fnResWithId.toJson() as Map<String, dynamic>;
      expect(fnJson1['functionResponse']['id'], 'fn_id_1');

      final fnResNoId = FunctionResponse('fn', {'val': 456});
      final fnJson2 = fnResNoId.toJson() as Map<String, dynamic>;
      expect(fnJson2['functionResponse'].containsKey('id'), isFalse);

      // 4. Schema.anyOf and Schema.object with optionalProperties null, propertyOrdering, anyOf
      final anyOfSchema = Schema.anyOf(schemas: [Schema.string()]);
      expect(anyOfSchema.type, SchemaType.anyOf);
      expect((anyOfSchema.toJson() as Map<String, dynamic>)['anyOf'], isNotNull);

      final sObj = Schema.object(
        properties: {'k': Schema.string()},
        optionalProperties: null,
        propertyOrdering: ['k'],
      );
      final sObjJson = sObj.toJson() as Map<String, dynamic>;
      expect(sObjJson['required'], ['k']);
      expect(sObjJson['propertyOrdering'], ['k']);

      // JSONSchema.object with null optionalProperties
      final jsonObject = JSONSchema.object(properties: {'prop': JSONSchema.string()});
      expect((jsonObject.toJson() as Map<String, dynamic>)['required'], ['prop']);

      // 5. SchemaType ref and anyOf toJson
      expect(SchemaType.ref.toJson(), 'null');
      expect(SchemaType.anyOf.toJson(), 'null');

      // 6. toCoreRealtimeInputConfig coverage
      final realtimeConfig1 = RealtimeInputConfig(
        automaticActivityDetection: ActivityDetectionConfig(
          startSensitivity: Sensitivity.low,
          endSensitivity: Sensitivity.low,
        ),
        activityHandling: ActivityHandling.noInterrupt,
        turnCoverage: TurnCoverage.allInput,
      );
      final coreCfg1 = toCoreRealtimeInputConfig(realtimeConfig1);
      expect(coreCfg1?.activityHandling, core.ActivityHandling.NO_INTERRUPTION);
      expect(coreCfg1?.turnCoverage, core.TurnCoverage.TURN_INCLUDES_ALL_INPUT);
      expect(coreCfg1?.automaticActivityDetection?.startOfSpeechSensitivity, core.StartSensitivity.START_SENSITIVITY_LOW);
      expect(coreCfg1?.automaticActivityDetection?.endOfSpeechSensitivity, core.EndSensitivity.END_SENSITIVITY_LOW);

      final realtimeConfig2 = RealtimeInputConfig(
        automaticActivityDetection: ActivityDetectionConfig(
          startSensitivity: Sensitivity.high,
          endSensitivity: Sensitivity.high,
        ),
        activityHandling: ActivityHandling.interrupt,
        turnCoverage: TurnCoverage.audioActivityAndAllVideo,
      );
      final coreCfg2 = toCoreRealtimeInputConfig(realtimeConfig2);
      expect(coreCfg2?.activityHandling, core.ActivityHandling.START_OF_ACTIVITY_INTERRUPTS);
      expect(coreCfg2?.turnCoverage, core.TurnCoverage.TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO);
      expect(coreCfg2?.automaticActivityDetection?.startOfSpeechSensitivity, core.StartSensitivity.START_SENSITIVITY_HIGH);
      expect(coreCfg2?.automaticActivityDetection?.endOfSpeechSensitivity, core.EndSensitivity.END_SENSITIVITY_HIGH);
    });
  });
}
