import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Owns the Gemini Live WebSocket session, the declared tools and every
/// outbound message.
class FunctionCallingLiveService {
  FunctionCallingLiveService()
    : _genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);

  final GoogleGenAI _genAI;
  LiveSession? _session;

  bool get hasSession => _session != null;

  /// Opens a session. Does NOT store it; call [attach] with the result so the
  /// caller controls ordering relative to its own state updates.
  Future<LiveSession> connect({
    required VoidCallback onOpen,
    required void Function(LiveServerMessage message) onMessage,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function(int? code, String? reason) onClose,
  }) async {
    final modelToUse = ApiKeyStore.liveModel.isNotEmpty
        ? ApiKeyStore.liveModel
        : kCompatibilityLiveModel;

    return _genAI.live.connect(
      LiveConnectParameters(
        model: modelToUse,
        config: buildExampleAudioGenerationConfig(temperature: 0.7),
        outputAudioTranscription: AudioTranscriptionConfig(),
        systemInstruction: Content(
          parts: [
            Part(
              text:
                  'You are a helpful assistant with tool access. '
                  'Prefer tool calls for weather, time, exchange rate, currency conversion, place search, and reminders. '
                  'If a user asks for multiple actions, call tools as needed and then summarize clearly.',
            ),
          ],
        ),
        tools: [
          Tool(
            functionDeclarations: [
              FunctionDeclaration(
                name: 'get_weather',
                description:
                    'Get weather by location with optional unit (celsius/fahrenheit).',
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'location': {'type': 'STRING'},
                    'unit': {
                      'type': 'STRING',
                      'enum': ['celsius', 'fahrenheit'],
                    },
                  },
                  'required': ['location'],
                },
              ),
              FunctionDeclaration(
                name: 'get_current_time',
                description: 'Get current time for a timezone.',
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'timezone': {'type': 'STRING'},
                  },
                },
              ),
              FunctionDeclaration(
                name: 'get_exchange_rate',
                description: 'Get FX rate for a currency pair.',
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'base_currency': {'type': 'STRING'},
                    'quote_currency': {'type': 'STRING'},
                  },
                  'required': ['base_currency', 'quote_currency'],
                },
              ),
              FunctionDeclaration(
                name: 'convert_currency',
                description: 'Convert money from one currency to another.',
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'amount': {'type': 'NUMBER'},
                    'from_currency': {'type': 'STRING'},
                    'to_currency': {'type': 'STRING'},
                  },
                  'required': ['amount', 'from_currency', 'to_currency'],
                },
              ),
              FunctionDeclaration(
                name: 'search_places',
                description:
                    'Search places by query and optional city. Returns ranked results.',
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'query': {'type': 'STRING'},
                    'city': {'type': 'STRING'},
                    'limit': {'type': 'INTEGER'},
                  },
                  'required': ['query'],
                },
              ),
              FunctionDeclaration(
                name: 'create_reminder',
                description:
                    'Create a reminder with title, datetime and timezone.',
                behavior: Behavior.NON_BLOCKING,
                parameters: {
                  'type': 'OBJECT',
                  'properties': {
                    'title': {'type': 'STRING'},
                    'datetime': {'type': 'STRING'},
                    'timezone': {'type': 'STRING'},
                  },
                  'required': ['title', 'datetime'],
                },
              ),
            ],
          ),
        ],
        callbacks: LiveCallbacks(
          onOpen: onOpen,
          onMessage: onMessage,
          onError: onError,
          onClose: onClose,
        ),
      ),
    );
  }

  void attach(LiveSession session) => _session = session;

  void sendText(String text) => _session!.sendText(text);

  /// Sends a tool response when a session exists and [call] has an id + name.
  void sendToolResponse(
    FunctionCall call,
    Map<String, dynamic> result,
    FunctionResponseScheduling? scheduling,
  ) {
    if (_session != null && call.id != null && call.name != null) {
      _session!.sendToolResponse(
        functionResponses: [
          FunctionResponse(
            id: call.id!,
            name: call.name!,
            response: result,
            scheduling: scheduling,
          ),
        ],
      );
    }
  }

  void close() => _session?.close();
}
