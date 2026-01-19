import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import './platform/web_socket_service_stub.dart'
    if (dart.library.io) './platform/web_socket_service_io.dart'
    if (dart.library.html) './platform/web_socket_service_web.dart'
    as ws_connector;

import 'model/models.dart';

// Live API 콜백 정의
class LiveCallbacks {
  final void Function()? onOpen;
  final void Function(LiveServerMessage message)? onMessage;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function(int? closeCode, String? closeReason)? onClose;

  LiveCallbacks({this.onOpen, this.onMessage, this.onError, this.onClose});
}

// LiveConnectParameters 클래스 수정
class LiveConnectParameters {
  final String model;
  final LiveCallbacks callbacks;
  final GenerationConfig? config;
  final Content? systemInstruction;

  /// Enable transcription of user audio input
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Enable transcription of model audio output
  final AudioTranscriptionConfig? outputAudioTranscription;

  LiveConnectParameters({
    required this.model,
    required this.callbacks,
    this.config,
    this.systemInstruction,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
  });
}

// Live API 서비스 클래스
class LiveService {
  final String apiKey;
  final String apiVersion;

  // *** 추가: SDK 버전 및 User-Agent 정보 ***
  // final String _sdkVersion = '1.0.0'; // Dart SDK의 자체 버전
  // final String _dartVersion; // Dart 런타임 버전

  LiveService({
    required this.apiKey,
    this.apiVersion = 'v1beta',
    // required String dartVersion,
  });

  // *** 수정된 부분: 데이터 처리 로직을 별도 함수로 분리 ***
  void _handleWebSocketData(dynamic data, LiveCallbacks callbacks) {
    String jsonData;
    if (data is String) {
      jsonData = data;
    } else if (data is List<int>) {
      // Uint8List를 String으로 디코딩
      jsonData = utf8.decode(data);
    } else {
      callbacks.onError?.call(
        Exception(
          'Received unexpected data type from WebSocket: ${data.runtimeType}',
        ),
        StackTrace.current,
      );
      return;
    }

    try {
      final json = jsonDecode(jsonData);
      print('📥 Received JSON: $jsonData');
      final message = LiveServerMessage.fromJson(json);
      callbacks.onMessage?.call(message);
    } catch (e, st) {
      callbacks.onError?.call(e, st);
    }
  }

  // *** connect 메소드 전체를 아래 코드로 교체 ***
  Future<LiveSession> connect(LiveConnectParameters params) async {
    final websocketUri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.$apiVersion.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    final userAgent = 'google-genai-sdk/1.28.0 dart/3.8';

    print('🔌 Connecting to WebSocket at $websocketUri');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-goog-api-client': userAgent,
        'user-agent': userAgent,
      };
      final channel = await ws_connector.connect(websocketUri, headers);
      final session = LiveSession._(channel);
      final setupCompleter = Completer<void>();

      StreamSubscription? streamSubscription;
      streamSubscription = channel.stream.listen(
        (data) {
          final jsonData = data is String
              ? data
              : utf8.decode(data as List<int>);
          print('📥 Received: $jsonData');

          if (!setupCompleter.isCompleted) {
            try {
              // final json = jsonDecode(jsonData);
              // setupComplete 응답이 별도로 오지 않고, 첫 응답이 오면 성공으로 간주
              setupCompleter.complete();
            } catch (e) {
              // 파싱 실패 무시
            }
          }
          _handleWebSocketData(data, params.callbacks);
        },
        onError: (error, stackTrace) {
          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(error, stackTrace);
          }
          params.callbacks.onError?.call(error, stackTrace);
        },
        onDone: () {
          params.callbacks.onClose?.call(
            channel.closeCode,
            channel.closeReason,
          );
          streamSubscription?.cancel();
        },
        cancelOnError: true,
      );

      // 3. 연결 성공 후 onOpen 콜백 호출
      params.callbacks.onOpen?.call();

      final modelName = params.model.startsWith('models/')
          ? params.model
          : 'models/${params.model}';

      // 4. setup 메시지 생성 및 전송
      final setupMessage = LiveClientMessage(
        setup: LiveClientSetup(
          model: modelName,
          generationConfig: params.config,
          systemInstruction: params.systemInstruction,
          inputAudioTranscription: params.inputAudioTranscription,
          outputAudioTranscription: params.outputAudioTranscription,
        ),
      );
      session.sendMessage(setupMessage);

      // 5. 서버로부터 첫 응답 대기
      await setupCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("WebSocket setup timed out after 10 seconds.");
        },
      );

      return session;
    } catch (e) {
      print("Failed to connect or setup WebSocket: $e");
      rethrow;
    }
  }
}

// LiveSession 클래스는 이전과 동일
class LiveSession {
  final WebSocketChannel _channel;

  LiveSession._(this._channel);

  void sendMessage(LiveClientMessage message) {
    // 이미 채널이 닫혔는지 확인
    if (_channel.closeCode != null) {
      print(
        '⚠️ Warning: Attempted to send a message on a closed WebSocket channel.',
      );
      return;
    }
    final jsonString = jsonEncode(message.toJson());
    print('📤 Sending: $jsonString');
    _channel.sink.add(jsonString);
  }

  void sendText(String text) {
    final message = LiveClientMessage(
      clientContent: LiveClientContent(
        turns: [
          Content(parts: [Part(text: text)]),
        ],
        turnComplete: true, // 턴 완료 표시
      ),
    );
    sendMessage(message);
  }

  void sendAudio(List<int> audioBytes) {
    final base64Audio = base64Encode(audioBytes);
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(
        audio: Blob(mimeType: 'audio/pcm', data: base64Audio),
      ),
    );
    sendMessage(message);
  }

  Future<void> close() {
    return _channel.sink.close();
  }
}
