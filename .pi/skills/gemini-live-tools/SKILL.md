---
name: gemini-live-tools
description: Implement function calling, asynchronous non-blocking tools, streamed arguments, Google Maps grounding, Google Search, and code execution in Flutter using the Gemini Live API. Use when declaring tools, handling ToolCall and ToolCallCancellation messages, returning FunctionResponse, or grounding responses with real-world location and search data.
---

# Gemini Live Function Calling & Grounding Skill

This skill provides comprehensive instructions for executing function calls, non-blocking asynchronous tools, and grounding capabilities within a Gemini Live session.

---

## 🛠️ Tool Declaration & Schema Definition

Tools are declared in `LiveConnectParameters.tools` using `Tool` and `FunctionDeclaration`:

```dart
final weatherTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      name: 'getWeather',
      description: 'Fetch current weather conditions and temperature for a city.',
      parameters: {
        'type': 'OBJECT',
        'properties': {
          'city': {
            'type': 'STRING',
            'description': 'City name (e.g. "Seoul", "San Francisco")',
          },
          'unit': {
            'type': 'STRING',
            'enum': ['celsius', 'fahrenheit'],
            'description': 'Temperature unit',
          },
        },
        'required': ['city'],
      },
    ),
  ],
);
```

---

## ⚡ Asynchronous & Non-Blocking Tools (`Behavior.NON_BLOCKING`)

In Gemini Live, long-running tools (e.g. database lookups, payment processing, smart home actions) should be defined with `Behavior.NON_BLOCKING` so the AI can continue conversing with the user while the tool runs in the background:

```dart
final backgroundTaskTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      name: 'orderCoffee',
      description: 'Order coffee in the background.',
      behavior: Behavior.NON_BLOCKING, // AI will not stall or block dialogue
      parameters: {
        'type': 'OBJECT',
        'properties': {
          'item': {'type': 'STRING'},
        },
        'required': ['item'],
      },
    ),
  ],
);
```

---

## 🔄 Handling Tool Calls & Sending Tool Responses

Listen for `message.toolCall` in `LiveCallbacks.onMessage` and return results via `session.sendToolResponse`:

```dart
void handleServerMessage(LiveSession session, LiveServerMessage message) async {
  // 1. Tool Call Received
  if (message.toolCall != null) {
    final calls = message.toolCall!.functionCalls ?? [];
    final responses = <FunctionResponse>[];

    for (final call in calls) {
      debugPrint('Executing tool: ${call.name} (id: ${call.id})');
      debugPrint('Arguments: ${call.args}');

      if (call.name == 'getWeather') {
        final city = call.args?['city'] as String? ?? 'Seoul';
        // Execute your local logic or API call
        final result = {
          'temperature': 21.5,
          'condition': 'Partly Cloudy',
          'city': city,
        };

        responses.add(
          FunctionResponse(
            name: call.name,
            id: call.id, // MUST match the call ID
            response: result,
          ),
        );
      }
    }

    // Send completed responses back to the model
    if (responses.isNotEmpty) {
      await session.sendToolResponse(responses);
    }
  }

  // 2. Handle Tool Call Cancellations (e.g., user interrupted the model)
  if (message.toolCallCancellation != null) {
    final canceledIds = message.toolCallCancellation!.ids ?? [];
    debugPrint('Tool calls canceled by user barge-in: $canceledIds');
    // Abort pending local HTTP requests or background jobs
  }
}
```

---

## 🌍 Google Maps & Search Grounding

Empower Gemini Live with real-time Google search and geographic location data:

### Google Maps Grounding
```dart
final mapsTool = Tool(
  googleMaps: GoogleMaps(
    groundingTypes: ['places', 'routing'],
  ),
);
```

### Google Search Grounding
```dart
final searchTool = Tool(
  googleSearch: GoogleSearch(),
);
```

### Python Code Execution
```dart
final codeExecutionTool = Tool(
  codeExecution: CodeExecution(),
);
```

### Connecting with Multiple Tools
```dart
await controller.connect(
  LiveConnectParameters(
    model: LiveModels.gemini38Live,
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    tools: [
      weatherTool,
      mapsTool,
      searchTool,
    ],
  ),
);
```

---

## 🚨 Critical Rules for AI Agents

1. **Always match `FunctionResponse.id` with `FunctionCall.id`:**
   If the ID does not match, the server cannot link the result to the turn, resulting in an `ArgumentError` or session closure.
2. **Always handle `toolCallCancellation`:**
   When a user interrupts the session during tool execution, Gemini Live emits a cancellation event. Stop any ongoing heavy compute or side effects.
3. **Keep blocking tools under 500ms:**
   If a tool takes longer than 500ms and is not marked `Behavior.NON_BLOCKING`, conversational latency will spike noticeably.
