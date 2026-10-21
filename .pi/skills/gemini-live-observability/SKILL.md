---
name: gemini-live-observability
description: Implement real-time token usage accounting, modality-specific USD/KRW cost estimation, usage monitor badges, and structured WebSocket diagnostics logging in Flutter using the Gemini Live API. Use when tracking live session token consumption (GeminiTokenUsageTracker, GeminiPricingRates), displaying cost badges (GeminiLiveUsageBadge, CupertinoGeminiLiveUsageBadge), or configuring severity-filtered WebSocket traffic logging (GeminiLiveLogger).
---

# Gemini Live Observability, Cost Tracking & Logging Skill

This skill covers real-time token accounting, modality-aware USD/KRW cost estimation, UI usage badges, and structured WebSocket diagnostic logging in `package:gemini_live`.

---

## 💰 1. Real-Time Token & Cost Tracking (`GeminiTokenUsageTracker`)

The Gemini Live WebSocket emits `UsageMetadata` on server messages with per-modality breakdowns (`AUDIO`, `VIDEO`, `IMAGE`, `TEXT`, plus `thoughtsTokenCount` and `cachedContentTokenCount`). `GeminiTokenUsageTracker` is a reactive `ChangeNotifier` that aggregates these metrics in real time and computes estimated costs in USD and KRW.

### Automatic Wiring via `GeminiLiveSessionController`

Every `GeminiLiveSessionController` automatically creates (or accepts) a `GeminiTokenUsageTracker` and feeds it incoming server messages:

```dart
import 'package:gemini_live/gemini_live.dart';

// Optional: customize model pricing tier or USD->KRW exchange rate
final tracker = GeminiTokenUsageTracker(
  model: LiveModels.gemini38Live,
  usdToKrwRate: 1400.0,
);

final controller = GeminiLiveSessionController(
  liveService: genAI.live,
  tokenTracker: tracker,
);
```

### Reading Metrics & Formatted Cost Strings

```dart
// Total & top-level token counters
final int total = controller.tokenTracker.totalTokens;
final int prompt = controller.tokenTracker.promptTokens;
final int response = controller.tokenTracker.responseTokens;
final int thoughts = controller.tokenTracker.thoughtsTokens;
final int cached = controller.tokenTracker.cachedTokens;

// Per-modality token counters
final int audioIn = controller.tokenTracker.audioInputTokens;
final int audioOut = controller.tokenTracker.audioOutputTokens;
final int videoIn = controller.tokenTracker.videoInputTokens;
final int imageIn = controller.tokenTracker.imageInputTokens;
final int textIn = controller.tokenTracker.textInputTokens;
final int textOut = controller.tokenTracker.textOutputTokens;

// Estimated costs & human-readable formatting
final double usd = controller.tokenTracker.estimatedCostUsd;
final double krw = controller.tokenTracker.estimatedCostKrw;
final String tokensLabel = controller.tokenTracker.formatTokens(); // e.g. "1,250 tokens"
final String costLabel = controller.tokenTracker.formatCost();     // e.g. "$0.0042 (약 6원)"
final String usdOnly = controller.tokenTracker.formatCost(showKrw: false); // e.g. "$0.0042"
```

### Custom Pricing Rates (`GeminiPricingRates`)

`GeminiPricingRates.forModel(modelName)` automatically selects official Google AI rates per 1M tokens for `gemini-3.8-live`, `gemini-3.5-live-translate-preview`, `gemini-3.5-transcribe-live`, `gemini-2.5-flash-native-audio`, and `flash-lite`. You can also supply custom rates:

```dart
final customTracker = GeminiTokenUsageTracker(
  model: LiveModels.gemini38Live,
  pricingRates: const GeminiPricingRates(
    textInputPerM: 0.75,
    audioInputPerM: 1.00,
    imageInputPerM: 0.75,
    videoInputPerM: 0.75,
    textOutputPerM: 3.75,
    audioOutputPerM: 12.00,
  ),
);
```

### Manual Wiring with Low-Level `LiveSession` or `compat/firebase_ai.dart`

- **Low-level `LiveSession`**: Call `tracker.recordMessage(message)` inside `LiveCallbacks.onMessage`.
- **Firebase AI Compat Layer**: Access `session.tokenTracker` directly on any compat `LiveSession`.

---

## 📊 2. Pre-Built Usage Monitor Widgets

### Material 3 (`GeminiLiveUsageBadge` & `GeminiLiveUsageDetailsDialog`)

```dart
Row(
  children: [
    // Tapping opens GeminiLiveUsageDetailsDialog with full modality breakdown
    GeminiLiveUsageBadge(
      tracker: controller.tokenTracker,
      compact: false, // Set true to show token count only
    ),
  ],
)
```

### iOS / Cupertino (`CupertinoGeminiLiveUsageBadge`)

```dart
CupertinoGeminiLiveUsageBadge(
  tracker: controller.tokenTracker,
  compact: false, // Tapping opens a native CupertinoAlertDialog breakdown
)
```

---

## 🔍 3. Structured Diagnostics & Traffic Logging (`GeminiLiveLogger`)

Use `GeminiLiveLogger` to inspect WebSocket handshakes, outgoing client frames (`📤`), incoming server events (`📥`), warnings (`⚠️`), and errors (`❌`) with severity filtering.

### Log Levels (`GeminiLiveLogLevel`)
- `GeminiLiveLogLevel.traffic`: Verbose network traffic (raw JSON payloads & media packets)
- `GeminiLiveLogLevel.info`: Connection lifecycle and setup events (default)
- `GeminiLiveLogLevel.warning`: Deprecations, fallbacks, parameter adjustments
- `GeminiLiveLogLevel.error`: Connection failures and WebSocket errors
- `GeminiLiveLogLevel.none`: Completely silent (recommended for production release builds)

### Wiring `GeminiLiveLogger` to `GoogleGenAI`

```dart
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

// 1. Use preset loggers (verbose, standard, silent)
final logger = kReleaseMode
    ? GeminiLiveLogger.silent
    : GeminiLiveLogger.verbose;

// 2. Or route logs to Crashlytics / Sentry / custom analytics sink
final customLogger = GeminiLiveLogger(
  level: GeminiLiveLogLevel.info,
  output: (formattedMessage, level) {
    debugPrint(formattedMessage);
    if (level == GeminiLiveLogLevel.error) {
      // Forward error telemetry to your observability backend
    }
  },
);

final genAI = GoogleGenAI(
  apiKey: apiKey,
  logger: customLogger.toCallback(),
);
```

---

## 🚨 Critical Rules for AI Agents

1. **Do NOT poll `tokenTracker`**: `GeminiTokenUsageTracker` extends `ChangeNotifier`. Wrap custom UI in `ListenableBuilder(listenable: controller.tokenTracker, ...)` or use `GeminiLiveUsageBadge` which listens automatically.
2. **Resetting session metrics**: Call `controller.clearHistory()` (or `tracker.reset()`) when starting a fresh conversation so token and cost counters reset to zero.
3. **Avoid `GeminiLiveLogLevel.traffic` in production**: Raw audio/video base64 frames generate high log volume; gate `verbose` logging behind `kDebugMode`.
