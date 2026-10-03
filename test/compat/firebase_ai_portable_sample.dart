// Portable sample: written only against the firebase_ai 4.x Live API.
//
// Nothing below the import may use gemini_live-only APIs. Swapping the import
// for `package:firebase_ai/firebase_ai.dart` must still compile; see
// tool/check_firebase_ai_compat.sh.
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:gemini_live/compat/firebase_ai.dart';

/// Builds the model the way the firebase_ai docs do.
LiveGenerativeModel buildSampleModel(FirebaseAI ai) => ai.liveGenerativeModel(
      model: 'gemini-2.5-flash-native-audio-preview-12-2025',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'Puck', languageCode: 'ko-KR'),
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
        temperature: 0.7,
        mediaResolution: MediaResolution.low,
        realtimeInputConfig: RealtimeInputConfig(
          automaticActivityDetection: ActivityDetectionConfig(
            startSensitivity: Sensitivity.high,
            silenceDurationMS: 500,
          ),
          activityHandling: ActivityHandling.interrupt,
          turnCoverage: TurnCoverage.onlyActivity,
        ),
        contextWindowCompression: ContextWindowCompressionConfig(
          triggerTokens: 1000,
          slidingWindow: SlidingWindow(targetTokens: 500),
        ),
      ),
      systemInstruction: Content.system('Answer briefly.'),
      tools: [
        Tool.functionDeclarations([
          FunctionDeclaration(
            'getWeather',
            'Returns the weather for a city.',
            parameters: {
              'city': Schema.string(description: 'City name'),
              'days': Schema.integer(minimum: 1, maximum: 7),
            },
            optionalParameters: ['days'],
          ),
        ]),
        Tool.googleSearch(),
      ],
    );

/// Sends one of each client message type.
Future<void> sendSampleInput(LiveSession session, Stream<Uint8List> mic) async {
  await session.sendAudioRealtime(
      InlineDataPart('audio/pcm;rate=16000', Uint8List.fromList([1, 2])));
  await session.sendVideoRealtime(
      InlineDataPart('image/jpeg', Uint8List.fromList([3, 4])));
  await session.sendTextRealtime('hello');
  await session.sendMediaStream(
      mic.map((chunk) => InlineDataPart('audio/pcm;rate=16000', chunk)));
  await session.send(input: Content.text('What is Flutter?'), turnComplete: true);
}

/// What [handleSampleTurn] observed.
class SampleTurn {
  final text = StringBuffer();
  final captions = <String>[];
  final toolCalls = <String>[];
  final cancelledCalls = <String>[];
  var audioBytes = 0;
  var interrupted = false;
  String? resumeHandle;
  String? goAwayTimeLeft;
}

/// Reads server responses until the model completes a turn, answering tool
/// calls along the way.
Future<SampleTurn> handleSampleTurn(LiveSession session) async {
  final turn = SampleTurn();
  await for (final response in session.receive()) {
    final message = response.message;
    switch (message) {
      case LiveServerContent():
        for (final part in message.modelTurn?.parts ?? const <Part>[]) {
          if (part is TextPart) turn.text.write(part.text);
          if (part is InlineDataPart) turn.audioBytes += part.bytes.length;
        }
        if (message.outputTranscription?.text case final text?) {
          turn.captions.add(text);
        }
        if (message.interrupted == true) turn.interrupted = true;
        if (message.turnComplete == true) return turn;
      case LiveServerToolCall():
        for (final call in message.functionCalls ?? const <FunctionCall>[]) {
          turn.toolCalls.add('${call.name}(${call.args['city']})');
          await session.sendToolResponse(
              [FunctionResponse(call.name, {'tempC': 21}, id: call.id)]);
        }
      case LiveServerToolCallCancellation():
        turn.cancelledCalls.addAll(message.functionIds ?? const []);
      case GoingAwayNotice():
        turn.goAwayTimeLeft = message.timeLeft;
      case SessionResumptionUpdate():
        turn.resumeHandle = message.newHandle;
      default:
        break;
    }
  }
  return turn;
}

/// Maps the exceptions firebase_ai apps commonly catch.
String describeSampleError(Object error) => switch (error) {
      InvalidApiKey() => 'invalid key',
      QuotaExceeded() => 'quota',
      UnsupportedUserLocation() => 'location',
      ServiceApiNotEnabled() => 'api disabled',
      ServerException() => 'server',
      FirebaseAIException() => 'firebase ai',
      FirebaseAISdkException() => 'sdk',
      _ => 'other',
    };
