---
name: gemini-live-session-auth
description: Implement secure ephemeral client auth tokens, session resumption, connection lifecycle management, and automatic reconnection backoff in Flutter using the Gemini Live API. Use when minting short-lived client tokens (AuthTokensService), saving/resuming session handles (SessionResumptionConfig), or handling abnormal disconnects (code 1006) and GoAway notices.
---

# Gemini Live Session & Ephemeral Auth Skill

This skill provides best practices for securing client applications with short-lived tokens and maintaining resilient, uninterrupted Live sessions across network drops.

---

## 🔐 Ephemeral Client Auth Tokens (`genAI.authTokens`)

**Never embed your master Gemini API key in mobile client apps.** Instead, have your backend server mint an ephemeral, constrained client token using `AuthTokensService`.

### 1. Server-Side Token Minting (Backend)

```dart
import 'package:gemini_live/gemini_live.dart';

final serverGenAI = GoogleGenAI(apiKey: 'MASTER_BACKEND_API_KEY');

Future<String> mintClientToken() async {
  final token = await serverGenAI.authTokens.create(
    CreateAuthTokenConfig(
      // Short expiry (e.g. 15 to 30 minutes)
      expireTime: DateTime.now().add(const Duration(minutes: 30)).toUtc().toIso8601String(),
      uses: 1, // Single-use connection token
      // Lock model & modalities to prevent abuse
      liveConnectConstraints: LiveConnectConstraints(
        model: 'models/gemini-3.8-live',
        config: GenerationConfig(
          responseModalities: [Modality.AUDIO],
          speechConfig: SpeechConfig.fromLiveVoice(GeminiLiveVoice.puck),
        ),
      ),
      // Prevent client from overriding voice or model
      lockAdditionalFields: ['speechConfig', 'model'],
    ),
  );

  // Returns resource name, e.g. "auth_tokens/abcdef123456"
  return token.name!;
}
```

### 2. Client-Side Safe Connection (Flutter Mobile App)

The mobile client uses the token directly in place of an API key:

```dart
final clientGenAI = GoogleGenAI(
  apiKey: ephemeralTokenString, // e.g., "auth_tokens/abcdef123456"
  apiVersion: 'v1alpha',        // Ephemeral tokens currently use v1alpha endpoint
);

final session = await clientGenAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.8-live',
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    callbacks: LiveCallbacks(...),
  ),
);
```

---

## 🔄 Session Resumption & Reconnection

When mobile devices switch Wi-Fi/LTE networks or experience momentary drops, resume the exact conversational context using session handles:

### Step 1: Persist Resumption Handles
Listen for `sessionResumptionUpdate` events during the active session:

```dart
String? _lastResumptionHandle;

void onMessage(LiveServerMessage message) {
  // Update saved handle whenever server emits a new one
  if (message.sessionResumptionUpdate?.newHandle != null) {
    _lastResumptionHandle = message.sessionResumptionUpdate!.newHandle;
    debugPrint('Saved new resumption handle: $_lastResumptionHandle');
  }

  // Server notifies it will terminate soon
  if (message.goAway != null) {
    debugPrint('Server GoAway received. Reconnecting proactively...');
    reconnectWithHandle(_lastResumptionHandle);
  }
}
```

### Step 2: Resume Session on Reconnection
Pass the persisted handle to `SessionResumptionConfig`:

```dart
Future<void> reconnectWithHandle(String? handle) async {
  if (handle == null) return;

  await controller.connect(
    LiveConnectParameters(
      model: LiveModels.gemini38Live,
      config: GenerationConfig(responseModalities: [Modality.AUDIO]),
      // Pass the saved resumption handle
      sessionResumption: SessionResumptionConfig(handle: handle),
      callbacks: LiveCallbacks(
        onClose: (code, reason) {
          if (code == 1006) {
            // Abnormal closure: execute exponential backoff reconnect
            _scheduleReconnect();
          }
        },
      ),
    ),
  );
}
```

---

## 📈 Resilient Reconnection Pattern (Exponential Backoff)

```dart
int _reconnectAttempts = 0;

void scheduleReconnect() {
  _reconnectAttempts++;
  final delaySec = (1 << _reconnectAttempts).clamp(1, 30); // 2s, 4s, 8s, ... max 30s
  
  Timer(Duration(seconds: delaySec), () async {
    try {
      await reconnectWithHandle(_lastResumptionHandle);
      _reconnectAttempts = 0; // Reset on success
    } catch (e) {
      scheduleReconnect(); // Retry on failure
    }
  });
}
```

---

## 🚨 Critical Rules for AI Agents

1. **Never pass `sessionResumption.transparent` on standard Gemini Live:**
   `transparent: true` is Vertex AI specific and throws `UnsupportedError` on Google AI Studio endpoints.
2. **Handle Close Code 1006:**
   Code `1006` indicates abrupt network loss. Always check if a valid resumption handle exists before falling back to creating a completely fresh session.
3. **Lock fields in ephemeral tokens:**
   Always include `lockAdditionalFields` when minting tokens on your backend to ensure clients cannot request more expensive models or modalities.
