# Gemini Live API & Package Error Codes Specification

이 명세서는 `flutter_gemini_live` 패키지 및 Google Gemini Live API 사용 중 발생할 수 있는 클라이언트 예외, WebSocket 종료 코드, 서버 응답 턴 종료 이유(`TurnCompleteReason`), HTTP 상태 코드의 의미와 조치 방안을 상세히 정리한 문서입니다.

---

## 목차
1. [클라이언트 패키지 예외 (Dart Client Exceptions)](#1-클라이언트-패키지-예외-dart-client-exceptions)
2. [WebSocket 종료 코드 (WebSocket Close Codes)](#2-websocket-종료-코드-websocket-close-codes)
3. [서버 턴 종료 사유 (TurnCompleteReason Enum)](#3-서버-턴-종료-사유-turncompletereason-enum)
4. [REST API HTTP 상태 코드 (ApiClient Exceptions)](#4-rest-api-http-상태-코드-apiclient-exceptions)
5. [서버 세션 이탈 경고 (LiveServerGoAway)](#5-서버-세션-이탈-경고-liveservergoaway)
6. [트러블슈팅 및 가이드](#6-트러블슈팅-및-가이드)

---

## 1. 클라이언트 패키지 예외 (Dart Client Exceptions)

클라이언트 라이브러리 내부 검증 또는 연결 과정에서 발생하는 Dart 예외 클래스입니다.

| 예외 클래스 (Exception) | 발생 원인 (Cause) | 조치 방안 (Resolution) |
| :--- | :--- | :--- |
| **`TimeoutException`** | `LiveService.connect()` 실행 후 10초(`setupTimeout`) 내에 서버로부터 `setupComplete` 수신 응답이 오지 않음. | • API 키가 유효한지 확인<br>• 네트워크 연결 상태 및 프록시/방화벽의 WebSocket(`wss://`) 허용 여부 점검 |
| **`UnsupportedError`** | Gemini Live API 규격상 지원하지 않는 매개변수 설정 시 사전 차단:<br>• `sessionResumption.transparent == true`<br>• `explicitVadSignal != null`<br>• `inputAudioTranscription.languageCodes` (배열)<br>• `SafetySetting.method != null`<br>• `Tool.exaAiSearch != null` | • 미지원 파라미터를 해제하고 지원되는 대체 파라미터(`LanguageAuto`, `LanguageHints` 등)를 사용 |
| **`ArgumentError`** | 전달된 인자(Argument) 값이 프로토콜에 위배될 때 발생:<br>• `sendToolResponse`의 `functionResponses` 필수 필드(`id`, `name`, `response`) 누락<br>• 지원되지 않는 MIME 타입 오디오/비디오 캡처 데이터 전송 | • `ToolCall`에서 수신한 `id` 및 `name` 값을 정확히 대입<br>• 오디오 전송 시 `audio/pcm` 형식 준수 |

---

## 2. WebSocket 종료 코드 (WebSocket Close Codes)

WebSocket 커넥션 종료 시 `callbacks.onClose(closeCode, closeReason)`로 전달되는 표준 및 애플리케이션 종료 코드입니다.

| 종료 코드 (Close Code) | 명칭 (Name) | 의미 (Description) | 대처 방안 (Action) |
| :---: | :--- | :--- | :--- |
| **`1000`** | Normal Closure | 정상적인 연결 종료 (`session.close()` 호출 또는 대화 종료) | 별도 조치 불필요 |
| **`1001`** | Going Away | 서버 엔드포인트 이탈 (서버 재시작 또는 유지보수) | 지연 후 재연결 시도 |
| **`1006`** | Abnormal Closure | 비정상적 소켓 끊김 (TCP RST, TLS 핸드셰이크 실패, 네트워크 무응답) | 네트워크 상태 확인 및 자동 재연결 로직 수행 |
| **`1008`** | Policy Violation | 정책 위반 (잘못된 API Key, URL Query Parameter 오류) | API Key 및 쿼리 파라미터 점검 |
| **`1011`** | Internal Error | 백엔드 서버 내부 오류 | 잠시 후 재연결 시도 |
| **`4000` / `4003`** | Bad Request / Unauthorized | API 키 인증 실패 또는 클라이언트 Setup JSON 메세지 스키마 오류 | API 키 및 Setup 메시지 구조 확인 |
| **`4004`** | Quota Exceeded | API 호출 할당량 초과 (RPM / TPM Limit) | 호출 빈도 조절 또는 Google AI Studio 요금제 확인 |
| **`4008`** | Session Timeout | Gemini Live 최대 세션 허용 시간(예: 15~30분) 경과로 인한 자동 차단 | `SessionResumptionConfig`를 이용해 세션 재개 처리 |

---

## 3. 서버 턴 종료 사유 (TurnCompleteReason Enum)

모델 턴이 끝났을 때 `LiveServerMessage.serverContent.turnCompleteReason`에 포함되는 원인 코드입니다.

| Enum 값 (TurnCompleteReason) | 의미 및 발생 상황 (Meaning & Scenario) | 조치 방안 (Handling Strategy) |
| :--- | :--- | :--- |
| **`TOO_MANY_TOOL_CALLS`** | 모델이 연속된 툴 호출(Function Calling) 루프에 빠져 시스템 최대 안전 임계값을 초과함. | 툴 정의 및 시스템 프롬프트 수정하여 연속 호출 억제 |
| **`MALFORMED_FUNCTION_CALL`** | 모델이 전송한 툴 호출 JSON 스키마가 올바르지 않음. | 모델에게 툴 전송 형식 재요청 또는 인스턴스 재시도 |
| **`PROHIBITED_INPUT_CONTENT`** | 사용자가 입력한 프롬프트/이미지에 금지된 키워드/콘텐츠가 포함됨. | 사용자에게 입력 수정 안내 메시지 표시 |
| **`INPUT_IMAGE_CELEBRITY`** | 유명인/공인 얼굴이 포함된 이미지 입력 금지 정책 위반. | 다른 이미지 업로드 요청 |
| **`BLOCKLIST` / `GENERATED_CONTENT_BLOCKLIST`** | 시스템 차단 단어 목록(Blocklist)에 등록된 단어 감지. | 입력 내용 필터링 |
| **`GENERATED_CONTENT_SAFETY`** | Harm Category(Hate, Violence, Sexual, Harassment) 안전 정책에 의해 답변 생성 차단. | 안전 설정(`SafetySetting`) 임계값 조절 또는 대화 주제 변경 |
| **`MAX_REGENERATION_REACHED`** | 응답 생성을 위한 내부 재시도 횟수 한계 도달. | 대화 새로 시작 |

---

## 4. REST API HTTP 상태 코드 (ApiClient Exceptions)

`ApiClient.post()` 등의 HTTP REST 요청에서 발생하는 에러 상태 코드입니다.

```text
Exception: API Error: <statusCode> <responseBody>
```

| HTTP Status | 명칭 | 원인 및 설명 |
| :---: | :--- | :--- |
| **`400`** | Bad Request | JSON 본문 구조 오류 또는 필수 파라미터 누락 |
| **`401`** | Unauthorized | 유효하지 않거나 만료된 API 키 |
| **`403`** | Forbidden | 계정 결제 미연동 또는 API 접근 권한 없음 |
| **`404`** | Not Found | 잘못된 API 엔드포인트 URL 또는 지원되지 않는 모델명 |
| **`429`** | Too Many Requests | 분당 요청 수(RPM) 또는 토큰 수(TPM) 할당량 초과 |
| **`500` / `503`** | Internal Error | Google API 백엔드 서버의 일시적 장애 |

---

## 5. 서버 세션 이탈 경고 (LiveServerGoAway)

Gemini Live 연결 유지 중 서버로부터 `message.goAway` 메세지가 도착하는 경우입니다.

```dart
if (message.goAway != null) {
  final remainingSeconds = message.goAway!.timeRemaining;
  print('Session expiring in ${remainingSeconds}s. Reason: ${message.goAway!.reason}');
}
```

* **원인**: 백엔드 세션 최대 유지 시간에 다다랐을 때 사전에 예고 메세지가 전달됩니다.
* **권장 조치**: `message.sessionResumptionUpdate`에서 저장해둔 `newHandle`을 활용하여 연결 종료 전에 세션을 슬라이딩 재개(`SessionResumptionConfig`)하는 로직을 수행합니다.

---

## 6. 트러블슈팅 및 가이드

### 코드 구현 예시 (에러 처리 패턴)

```dart
final genAI = GoogleGenAI(
  apiKey: 'YOUR_API_KEY',
  logger: print, // 로그 활성화
);

try {
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      callbacks: LiveCallbacks(
        onOpen: () => print('Connected'),
        onMessage: (message) {
          // 1. 턴 종료 이유 검사
          final reason = message.serverContent?.turnCompleteReason;
          if (reason == TurnCompleteReason.TOO_MANY_TOOL_CALLS) {
            print('Tool call limit reached!');
          } else if (reason == TurnCompleteReason.GENERATED_CONTENT_SAFETY) {
            print('Content blocked by safety policy.');
          }
          
          // 2. 세션 만료 경고 검사
          if (message.goAway != null) {
            print('Session expiring soon: ${message.goAway!.timeRemaining}s left');
          }
        },
        onError: (error, stackTrace) {
          print('Error occurred: $error');
        },
        onClose: (code, reason) {
          print('Closed code: $code, reason: $reason');
          if (code == 4004) {
            print('Quota exceeded! Please check your API usage.');
          } else if (code == 1006) {
            print('Abnormal disconnect, attempting reconnect...');
          }
        },
      ),
    ),
  );
} on TimeoutException catch (e) {
  print('Connection timed out: $e');
} on UnsupportedError catch (e) {
  print('Configuration unsupported: $e');
} catch (e) {
  print('General error: $e');
}
```
