# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- Google의 Gemini 모델과 실시간, 멀티모달 대화를 가능하게 해주는 [실험적인 Gemini Live API](https://ai.google.dev/gemini-api/docs/live)용 Flutter 패키지입니다.
- **Firebase 의존성 Zero**: Firebase / Firebase AI Logic 설치 없이 직접 WebSocket으로 연동됩니다.
- 최신 Gemini Live 모델 지원 (`gemini-3.1-flash-live-preview`, `gemini-2.5-flash-native-audio-preview-12-2025`).
- 모델 사양에 따라 `TEXT`, `AUDIO`, `VIDEO` 응답 모다리티를 지원합니다.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 설치하기 (Installation)

Flutter 프로젝트에 패키지를 추가합니다:

```bash
flutter pub add gemini_live
```

Dart 코드에서 패키지를 임포트합니다:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 빠른 시작 (Quick Start)

20줄 미만의 간단한 코드로 Gemini Live 대화를 시작할 수 있습니다:

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. Gemini Live 클라이언트 초기화
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. Live API 연결
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('Live 세션 연결 완료!'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('에러: $error'),
        onClose: (code, reason) => print('연결 종료: $code - $reason'),
      ),
    ),
  );

  // 3. 메시지 전송
  session.sendText('안녕 Gemini, 농담 하나만 해줘!');
}
```

## 상세 문서 & 가이드 (Documentation)

상세한 가이드와 API 명세는 [`doc/`](doc/) 디렉토리에 모듈별로 정리되어 있습니다:

- **[AI Agent Skill 가이드](SKILL.md)**: AI 코딩 어시스턴트(Antigravity, Cursor, Windsurf, Claude Code 등)가 이 패키지를 정확히 연동하도록 돕는 프롬프트 & 스킬 명세서
- **[API Reference 명세서](doc/api_reference.md)**: `GoogleGenAI`, `LiveSession`, `LiveServerMessage` 등 전체 클래스 및 메서드 명세
- **[UI 위젯 가이드 & 명세서](doc/widgets_guide.md)**: `GeminiLiveStatusBadge`, `GeminiLiveMicButton`, `GeminiLiveVoiceIndicator` 등 내장 UI 위젯 상세 사용법 및 전체 화면 예제
- **[고급 기능 설정 가이드](doc/advanced_configuration.md)**: Function Calling, VAD, 세션 재개, 오디오 전사, 실시간 텍스트/음성 번역, 그라운딩, 에페메럴 토큰 사용법
- **[에러 코드 & 트러블슈팅 명세서](doc/error_codes_specification.md)**: 발생 가능한 에러 코드, 종료 코드, `TurnCompleteReason` Enum, 트러블슈팅 가이드
- **[실행 가능한 예제 모음](examples/README.md)**: 기본 대화, 툴 호출, 카메라/오디오 스트리밍, Google Maps 그라운딩 CLI 예제

## 주요 기능 요약

* **실시간 통신**: 저지연 WebSocket 양방향 대화.
* **멀티모달 입력 & 스트리밍 출력**: 텍스트, 오디오, 카메라 프레임 입력 및 실시간 응답 스트리밍.
* **Function Calling (툴 연동)**: 동기/비동기 함수 실행 및 툴 응답 전송.
* **세션 재개 (Session Resumption)**: 끊긴 연결을 세션 핸들로 간편하게 복구.
* **Google Maps & Search 그라운딩**: 위치 및 경로 감지 답변 생성.
* **음성 활동 감지 (VAD)**: 자동 및 수동 VAD 지원.
* **실시간 음성 번역**: Speech-to-Speech 실시간 번역 (`TranslationConfig`).
* **내장 Flutter UI 위젯 제공**: 별도 추가 패키지 없이 바로 사용할 수 있는 실시간 UI 위젯(`GeminiLiveStatusBadge`, `GeminiLiveMicButton`, `GeminiLiveVoiceIndicator`).

| 데모 1: 치와와 vs 마핀 | 데모 2: 라브라도리 vs 프라이드치킨 |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="실시간 대화 데모" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="멀티모달 데모" width="400"/> |
| *치와와 vs 마핀* | *라브라도리 vs 프라이드치킨* |

---

## 내장 UI 위젯 (Pre-built UI Widgets)

Flutter 개발자가 즉시 연동하여 사용할 수 있도록 가볍고 의존성 없는 핵심 UI 위젯을 기본 제공합니다:

```dart
// 1. 실시간 세션 상태 배지 (InteractionStatus 및 연결 상태 연동)
GeminiLiveStatusBadge.fromFlags(
  isConnected: isConnected,
  isConnecting: isConnecting,
  interactionStatus: sessionStatus, // IN_PROGRESS / IDLE
)

// 2. 펄스 애니메이션 마이크 버튼
GeminiLiveMicButton(
  isRecording: isRecording,
  onPressed: toggleVoice,
)

// 3. 음성 파형 애니메이션 바 (음성 발화/스트리밍 시 실시간 애니메이션)
GeminiLiveVoiceIndicator(
  isSpeaking: isSpeaking,
  barCount: 5,
  color: Colors.blueAccent,
)
```

---

## 라이선스

이 프로젝트는 BSD 3-Clause 라이선스에 따라 제공됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
