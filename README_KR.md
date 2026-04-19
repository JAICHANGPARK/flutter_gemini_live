# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

---

- Google의 Gemini 모델과 실시간, 멀티모달 대화를 가능하게 해주는 [실험적인 Gemini Live API](https://ai.google.dev/gemini-api/docs/live)를 사용하기 위한 Flutter 패키지입니다.
- 이 패키지는 Firebase / Firebase AI Logic 사용 없이 활용가능 합니다.
- `gemini-live-2.5-flash-preview`, `gemini-2.5-flash-native-audio-preview-12-2025` 등 최신 Gemini Live 모델 계열을 사용할 수 있습니다.
- response_modalities : 모델 지원 범위에 따라 `TEXT`, `AUDIO`, `VIDEO` 사용 가능

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## ✨ 주요 기능

*   **실시간 통신**: WebSocket 연결을 통해 지연 시간이 짧은(low-latency) 양방향(two-way) 상호작용을 구축합니다.
*   **멀티모달 입력**: 하나의 대화 턴(turn)에서 텍스트, 이미지, 오디오를 함께 전송할 수 있습니다.
*   **스트리밍 응답**: 모델이 생성하는 텍스트 응답을 실시간 스트리밍으로 수신합니다.
*   **사용하기 쉬운 콜백**: `onOpen`, `onMessage`, `onError`, `onClose` 등 간단한 이벤트 기반 핸들러를 제공합니다.
*   **함수 호출(Function Calling)**: 모델이 외부 함수를 호출하고 결과를 받을 수 있습니다.
*   **세션 재개(Session Resumption)**: 연결이 끊어진 후 세션을 재개할 수 있습니다.
*   **음성 활동 감지(VAD)**: 자동 또는 수동으로 음성 활동을 감지합니다.
*   **실시간 미디어 청크**: 오디오/이미지 청크를 실시간으로 전송합니다.
*   **오디오 전사(Transcription)**: 음성 입력과 출력을 텍스트로 전사합니다.

| 데모 1: 치와와 vs 머핀 | 데모 2: 래브라두들 vs 프라이드 치킨 |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="실시간 대화 데모" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="멀티모달 입력 데모" width="400"/> |
| *치와와 vs 머핀* | *래브라두들 vs 프라이드 치킨* |

## 🏁 시작하기

### 사전 준비

이 패키지를 사용하려면 Google Gemini API 키가 필요합니다. [Google AI Studio](https://aistudio.google.com/app/apikey)에서 API 키를 발급받을 수 있습니다.

### 설치

`pubspec.yaml` 파일에 패키지를 추가하세요:

```yaml
dependencies:
  gemini_live: ^2026.3.21 # 최신 배포 버전을 사용하세요
```

또는 아래 명령어를 실행하세요(추천):

```bash
flutter pub add gemini_live
```

터미널에서 패키지를 설치하세요:

```bash
flutter pub get
```

이제 Dart 코드에서 패키지를 import 하세요:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 사용법

### 기본 예제

다음은 `gemini_live` 패키지를 사용하여 세션을 시작하고 메시지를 보내는 기본적인 예제입니다.

**보안 참고**: API 키를 코드에 직접 하드코딩하지 마세요. `flutter_dotenv`와 같은 패키지를 사용하여 `.env` 파일에 자격 증명을 안전하게 보관하는 것을 강력히 권장합니다.

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. API 키로 Gemini 초기화
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. Live API에 연결
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      LiveConnectParameters(
        model: 'gemini-live-2.5-flash-preview',
        config: GenerationConfig(responseModalities: [Modality.TEXT]),
        callbacks: LiveCallbacks(
          onOpen: () => print('✅ 연결 성공'),
          onMessage: (LiveServerMessage message) {
            // 3. 모델로부터 수신되는 메시지 처리
            if (message.text != null) {
              print('수신된 청크: ${message.text}');
            }
            if (message.serverContent?.turnComplete ?? false) {
              print('✅ 턴(Turn) 완료!');
            }
          },
          onError: (e, s) => print('🚨 오류 발생: $e'),
          onClose: (code, reason) => print('🚪 연결 종료'),
        ),
      ),
    );
  } catch (e) {
    print('연결 실패: $e');
  }
}

// 4. 모델에 메시지 전송
void sendMessage(String text) {
  session?.sendText(text);
}
```

### 🆕 주요 Live 기능

#### 함수 호출 (Function Calling)

모델이 외부 함수를 호출하고 결과를 받을 수 있습니다:

```dart
late final LiveSession session;

session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    tools: [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            name: 'get_weather',
            description: '도시별 날씨 조회',
            parameters: {
              'type': 'OBJECT',
              'properties': {
                'city': {'type': 'STRING'},
              },
              'required': ['city'],
            },
          ),
        ],
      ),
    ],
    callbacks: LiveCallbacks(
      onMessage: (LiveServerMessage message) {
        // 함수 호출 처리
        for (final call in message.toolCall?.functionCalls ?? const <FunctionCall>[]) {
          if (call.id == null || call.name == null) continue;
          print('함수 호출: ${call.name}');

          // 함수 실행 후 응답 전송
          session.sendFunctionResponse(
            id: call.id!,
            name: call.name!,
            response: {'result': 'success'},
          );
        }
      },
    ),
  ),
);
```

#### 실시간 입력 (Realtime Input)

오디오, 이미지 프레임, 텍스트를 실시간으로 전송합니다.
현재 `video` 필드는 `image/jpeg`, `image/png` 같은 `image/*` MIME 타입을 받습니다:

```dart
// 실시간 텍스트 전송
session.sendRealtimeText('실시간 텍스트 입력');

// 미디어 청크 전송
session.sendMediaChunks([
  Blob(mimeType: 'audio/pcm', data: base64Audio),
]);

// 결합된 실시간 입력
session.sendRealtimeInput(
  audio: Blob(mimeType: 'audio/pcm', data: base64Audio),
  video: Blob(mimeType: 'image/jpeg', data: base64Image),
  text: '텍스트 설명',
);

// 오디오 스트림 종료 신호
session.sendAudioStreamEnd();
```

#### 수동 활동 감지 (Manual Activity Detection)

자동 VAD를 비활성화하고 수동으로 제어:

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    realtimeInputConfig: RealtimeInputConfig(
      automaticActivityDetection: AutomaticActivityDetection(
        disabled: true, // 자동 감지 비활성화
      ),
    ),
  ),
);

// 활동 시작 신호
session.sendActivityStart();

// 음성 데이터 전송...

// 활동 종료 신호
session.sendActivityEnd();
```

#### 세션 재개 (Session Resumption)

연결이 끊어진 후 세션을 재개:

```dart
// 첫 연결 시 세션 재개 설정
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    sessionResumption: SessionResumptionConfig(
      handle: previousSessionHandle, // 이전 세션 핸들
    ),
  ),
);

// 세션 핸들 업데이트 수신
if (message.sessionResumptionUpdate != null) {
  final newHandle = message.sessionResumptionUpdate!.newHandle;
  // newHandle을 저장하여 나중에 사용
}
```

> Gemini API 참고: `SessionResumptionConfig.transparent` 는 현재 지원되지 않으며 setup 검증 단계에서 예외가 발생합니다.

#### 고급 설정

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-2.5-flash-native-audio-preview-12-2025',
    // 실시간 입력 설정
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
    // 오디오 전사
    inputAudioTranscription: AudioTranscriptionConfig(),
    outputAudioTranscription: AudioTranscriptionConfig(),
    // 컨텍스트 윈도우 압축
    contextWindowCompression: ContextWindowCompressionConfig(
      triggerTokens: '10000',
      slidingWindow: SlidingWindow(targetTokens: '5000'),
    ),
    // 능동성 설정
    proactivity: ProactivityConfig(proactiveAudio: true),
  ),
);
```

> Gemini API 참고: `AudioTranscriptionConfig.languageCodes` 는 현재 Gemini Live에서 지원되지 않습니다. 설정하지 않은 상태로 사용하세요.

#### 에페메럴 토큰 (Client-to-Server)

발급된 에페메럴 토큰(`auth_tokens/...`)을 `apiKey`로 사용하고 `apiVersion`을 `v1alpha`로 설정하세요:

```dart
final genAI = GoogleGenAI(
  apiKey: 'auth_tokens/your_ephemeral_token',
  apiVersion: 'v1alpha',
);
```

## 💬 라이브 채팅 데모

이 저장소(repository)에는 `gemini_live` 패키지의 기능을 보여주는 종합적인 예제 앱이 포함되어 있습니다.

### 데모 앱 실행하기

1.  **API 키 발급받기**: [Google AI Studio](https://aistudio.google.com/app/apikey)에서 Gemini API 키를 준비하세요.

2.  **프로젝트 설정**:
    *   이 저장소를 클론(clone)하세요.
    *   예제 앱에서 API 키를 화면에서 직접 입력할 수 있습니다.
    *   앱 실행 후 우측 상단 **Settings** 아이콘에서 API 키를 붙여 넣으세요.
    *   필요에 따라 마이크 및 사진 라이브러리 접근을 위한 플랫폼별 권한을 설정하세요.
    *   `example` 디렉토리에서 `flutter pub get`을 실행하세요.

3.  **앱 실행하기**:
    ```bash
    cd example
    flutter run
    ```

### 데모 페이지

예제 앱에는 다음 데모 페이지가 포함되어 있습니다:

1. **Chat Interface** - 기본 채팅 (텍스트, 이미지, 오디오)
2. **Live API Features** - 모든 새로운 기능 통합 데모
   - VAD, 전사, 세션 재개, 컨텍스트 압축 등
3. **Function Calling** - 함수 호출 데모 (날씨/시간/환율/장소/리마인더)
4. **Realtime Media** - 실시간 오디오/이미지 프레임 입력 데모

### CLI 스크립트 예제

`examples/` 디렉토리에 실행 가능한 스크립트 예제가 추가로 포함되어 있습니다:

- `examples/basic_usage.dart`
- `examples/function_calling.dart`
- `examples/realtime_audio_video.dart`
- `examples/manual_activity_detection.dart`
- `examples/session_resumption.dart`
- `examples/complete_features.dart`
- `examples/ephemeral_token.dart` (`GEMINI_EPHEMERAL_TOKEN`, `apiVersion: 'v1alpha'` 사용)

실행 방법은 [examples/README.md](/Users/jaichang/Documents/GitHub/flutter_gemini_live/examples/README.md)를 참고하세요.

### 앱 사용 방법

1.  **연결**: 앱이 자동으로 Gemini API에 연결을 시도합니다. 연결에 실패하면 **"재연결"** 버튼을 탭하세요.

2.  **텍스트 메시지 보내기**:
    -   하단의 텍스트 입력 필드에 메시지를 입력하세요.
    -   전송(**▶️**) 아이콘을 탭하세요.

3.  **이미지와 함께 메시지 보내기**:
    -   이미지(**🖼️**) 아이콘을 탭하여 갤러리를 여세요.
    -   이미지를 선택하면 미리보기가 나타납니다.
    -   (선택 사항) 이미지에 대해 질문할 내용을 입력하세요.
    -   전송(**▶️**) 아이콘을 탭하세요.

4.  **음성 메시지 보내기**:
    -   마이크(**🎤**) 아이콘을 탭하면 녹음이 시작되고 아이콘이 빨간색 정지(**⏹️**) 아이콘으로 바뀝니다.
    -   메시지를 말하세요.
    -   정지(**⏹️**) 아이콘을 다시 탭하면 녹음이 종료되고 오디오가 자동으로 전송됩니다.

## 📚 API 참조

### LiveSession 메서드

- `sendText(String text)` - 텍스트 메시지 전송
- `sendClientContent({List<Content>? turns, bool turnComplete})` - 멀티턴 콘텐츠 전송
- `sendRealtimeInput({...})` - 실시간 입력 전송 (오디오, 이미지 프레임, 텍스트)
- `sendMediaChunks(List<Blob> mediaChunks)` - 미디어 청크 전송
- `sendAudioStreamEnd()` - 오디오 스트림 종료 신호
- `sendRealtimeText(String text)` - 실시간 텍스트 전송
- `sendActivityStart()` / `sendActivityEnd()` - 활동 시작/종료 신호
- `sendToolResponse({required List<FunctionResponse> functionResponses})` - 툴 응답 전송
- `sendFunctionResponse({required String id, required String name, required Map<String, dynamic> response})` - 단일 함수 응답 전송
- `sendVideo(List<int> videoBytes, {String mimeType})` - Live API `video` 필드를 통해 이미지 바이트 전송 (`image/*` MIME 타입)
- `sendAudio(List<int> audioBytes)` - 오디오 전송
- `close()` - 연결 종료
- `isClosed` - 연결 상태 확인

### LiveServerMessage 속성

- `text` - 텍스트 응답
- `data` - Base64 인코딩된 인라인 데이터
- `serverContent` - 서버 콘텐츠 (modelTurn, turnComplete 등)
- `toolCall` - 툴 호출 요청
- `toolCallCancellation` - 툴 호출 취소
- `sessionResumptionUpdate` - 세션 재개 업데이트
- `voiceActivity` - 음성 활동 상태
- `voiceActivityDetectionSignal` - 음성 활동 감지 신호
- `goAway` - 서버 연결 종료 예고
- `usageMetadata` - 토큰 사용량 메타데이터

## 🤝 기여하기

버그 리포트, 기능 제안, 풀 리퀘스트(Pull Request) 등 모든 종류의 기여를 환영합니다! 이슈 트래커에 언제든지 이슈를 등록해주세요.

1.  이 저장소를 포크(Fork)하세요.
2.  기능 브랜치를 생성하세요 (`git checkout -b feature/AmazingFeature`).
3.  변경 사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`).
4.  브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`).
5.  풀 리퀘스트(Pull Request)를 열어주세요.

## 📜 라이선스

자세한 내용은 `LICENSE` 파일을 참고하세요.
