import 'dart:async';

import '../model/models.dart';

/// Callback signature for handling a Gemini Live function call.
typedef GeminiLiveToolHandler = FutureOr<Map<String, dynamic>> Function(
  Map<String, dynamic> args,
);

/// Callback signature for returning multimodal [FunctionResponsePart] items
/// alongside the structured JSON map in a [FunctionResponse].
typedef GeminiLiveMultimodalToolHandler = FutureOr<List<FunctionResponsePart>>
    Function(Map<String, dynamic> args);

/// A developer-friendly, inline implementation of [CallableTool] that wraps a
/// single [FunctionDeclaration] and a Dart [handler] closure.
///
/// Can be passed directly in `LiveConnectParameters(tools: [myTool])` or
/// `GeminiLiveChatView(tools: [myTool])` for automatic execution when
/// the Gemini Live server emits a `toolCall` message.
///
/// ```dart
/// final weatherTool = GeminiLiveFunctionTool(
///   name: 'get_weather',
///   description: 'Gets current weather for a city.',
///   parameters: Schema(
///     type: DataType.OBJECT,
///     properties: {'city': Schema(type: DataType.STRING)},
///     required: ['city'],
///   ),
///   behavior: Behavior.NON_BLOCKING,
///   scheduling: FunctionResponseScheduling.WHEN_IDLE,
///   handler: (args) async => {
///     'city': args['city'],
///     'temp_c': 22,
///     'condition': 'Sunny',
///   },
/// );
/// ```
class GeminiLiveFunctionTool implements CallableTool {
  /// The function name exposed to the model.
  final String name;

  /// Human-readable description of what the function does.
  final String description;

  /// Optional OpenAPI/JSON schema map describing the function's input parameters.
  final Map<String, dynamic>? parameters;

  /// Optional raw JSON schema alternative to [parameters].
  final dynamic parametersJsonSchema;

  /// Optional execution behavior (`Behavior.BLOCKING` or `Behavior.NON_BLOCKING`).
  final Behavior? behavior;

  /// Optional scheduling directive for non-blocking tool responses
  /// (`INTERRUPT`, `WHEN_IDLE`, or `SILENT`).
  final FunctionResponseScheduling? scheduling;

  /// Asynchronous or synchronous handler invoked with `FunctionCall.args`.
  final GeminiLiveToolHandler handler;

  /// Optional handler returning multimodal [FunctionResponsePart] attachments
  /// (e.g. images or audio blobs) to include in the [FunctionResponse].
  final GeminiLiveMultimodalToolHandler? multimodalPartsHandler;

  /// Creates an inline [GeminiLiveFunctionTool].
  const GeminiLiveFunctionTool({
    required this.name,
    required this.description,
    required this.handler,
    this.parameters,
    this.parametersJsonSchema,
    this.behavior,
    this.scheduling,
    this.multimodalPartsHandler,
  });

  /// Returns the [FunctionDeclaration] for this tool.
  FunctionDeclaration toDeclaration() {
    return FunctionDeclaration(
      name: name,
      description: description,
      parameters: parameters,
      parametersJsonSchema: parametersJsonSchema,
      behavior: behavior,
    );
  }

  @override
  FutureOr<Tool> tool() {
    return Tool(functionDeclarations: [toDeclaration()]);
  }

  /// Executes a single [FunctionCall] against [handler] and returns a
  /// `Part(functionResponse: ...)` ready to send back to the server.
  Future<Part> executeSingle(FunctionCall call) async {
    final args = call.args ?? const <String, dynamic>{};
    try {
      final result = await handler(args);
      final parts = multimodalPartsHandler != null
          ? await multimodalPartsHandler!(args)
          : null;
      return Part(
        functionResponse: FunctionResponse(
          id: call.id,
          name: call.name ?? name,
          response: result,
          scheduling: scheduling,
          parts: parts,
        ),
      );
    } catch (error) {
      return Part(
        functionResponse: FunctionResponse(
          id: call.id,
          name: call.name ?? name,
          response: <String, dynamic>{'error': error.toString()},
          scheduling: scheduling,
        ),
      );
    }
  }

  @override
  Future<List<Part>> callTool(List<FunctionCall> functionCalls) async {
    final matching = functionCalls.where((c) => c.name == name).toList();
    if (matching.isEmpty) return const <Part>[];
    return Future.wait(matching.map(executeSingle));
  }
}

/// A composite [CallableTool] registry that bundles multiple
/// [GeminiLiveFunctionTool] definitions into a single [Tool] declaration and
/// automatically routes incoming [FunctionCall]s by name.
class GeminiLiveToolRegistry implements CallableTool {
  final Map<String, GeminiLiveFunctionTool> _toolsByName = {};

  /// Creates a [GeminiLiveToolRegistry] with an optional initial list of [tools].
  GeminiLiveToolRegistry([Iterable<GeminiLiveFunctionTool> tools = const []]) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// Registers or replaces a [GeminiLiveFunctionTool] in the registry.
  void register(GeminiLiveFunctionTool tool) {
    _toolsByName[tool.name] = tool;
  }

  /// Removes a tool by [name]. Returns `true` if removed.
  bool unregister(String name) => _toolsByName.remove(name) != null;

  /// All registered [GeminiLiveFunctionTool] instances.
  List<GeminiLiveFunctionTool> get tools =>
      List<GeminiLiveFunctionTool>.unmodifiable(_toolsByName.values);

  /// Whether a tool with [name] is registered.
  bool contains(String name) => _toolsByName.containsKey(name);

  @override
  FutureOr<Tool> tool() {
    return Tool(
      functionDeclarations:
          _toolsByName.values.map((t) => t.toDeclaration()).toList(),
    );
  }

  @override
  Future<List<Part>> callTool(List<FunctionCall> functionCalls) async {
    final futures = <Future<Part>>[];
    for (final call in functionCalls) {
      final target = _toolsByName[call.name];
      if (target != null) {
        futures.add(target.executeSingle(call));
      }
    }
    if (futures.isEmpty) return const <Part>[];
    return Future.wait(futures);
  }
}
