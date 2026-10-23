// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Function Calling Models
// ============================================================================

/// One streamed partial argument value for a function call.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class PartialArg {
  final bool? boolValue;
  final String? jsonPath;
  final String? nullValue;
  final double? numberValue;
  final String? stringValue;
  final bool? willContinue;

  PartialArg({
    this.boolValue,
    this.jsonPath,
    this.nullValue,
    this.numberValue,
    this.stringValue,
    this.willContinue,
  });

  factory PartialArg.fromJson(Map<String, dynamic> json) =>
      _$PartialArgFromJson(json);

  Map<String, dynamic> toJson() => _$PartialArgToJson(this);
}

/// A tool invocation requested by the model.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionCall {
  final String? id;
  final String? name;
  final Map<String, dynamic>? args;
  final List<PartialArg>? partialArgs;
  final bool? willContinue;

  FunctionCall({
    this.id,
    this.name,
    this.args,
    this.partialArgs,
    this.willContinue,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionCallToJson(this);
}

/// A server-side tool call embedded in a model part.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ToolCall {
  final String? id;
  final ToolType? toolType;
  final Map<String, dynamic>? args;

  ToolCall({this.id, this.toolType, this.args});

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);
}

/// The client-side result of a server-side tool call.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ToolResponse {
  final String? id;
  final ToolType? toolType;
  final Map<String, dynamic>? response;

  ToolResponse({this.id, this.toolType, this.response});

  factory ToolResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResponseToJson(this);
}

/// Inline binary data returned from a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponseBlob {
  final String? mimeType;
  final String? data;
  final String? displayName;

  FunctionResponseBlob({this.mimeType, this.data, this.displayName});

  /// Creates a [FunctionResponseBlob] by base64-encoding raw [bytes].
  factory FunctionResponseBlob.fromBytes({
    required List<int> bytes,
    required String mimeType,
    String? displayName,
  }) => FunctionResponseBlob(
    mimeType: mimeType,
    data: base64Encode(bytes),
    displayName: displayName,
  );

  /// Decodes the base64 [data] payload into raw bytes, if present.
  Uint8List? get bytes => data == null ? null : base64Decode(data!);

  factory FunctionResponseBlob.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseBlobFromJson({
        ...json,
        if (json['data'] is List<int>)
          'data': base64Encode(json['data'] as List<int>),
        if (!json.containsKey('mime_type') && json.containsKey('mimeType'))
          'mime_type': json['mimeType'],
        if (!json.containsKey('display_name') &&
            json.containsKey('displayName'))
          'display_name': json['displayName'],
      });

  Map<String, dynamic> toJson() => _$FunctionResponseBlobToJson(this);
}

/// File metadata returned from a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponseFileData {
  final String? fileUri;
  final String? mimeType;
  final String? displayName;

  FunctionResponseFileData({this.fileUri, this.mimeType, this.displayName});

  factory FunctionResponseFileData.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFileDataFromJson({
        ...json,
        if (!json.containsKey('file_uri') && json.containsKey('fileUri'))
          'file_uri': json['fileUri'],
        if (!json.containsKey('mime_type') && json.containsKey('mimeType'))
          'mime_type': json['mimeType'],
        if (!json.containsKey('display_name') &&
            json.containsKey('displayName'))
          'display_name': json['displayName'],
      });

  Map<String, dynamic> toJson() => _$FunctionResponseFileDataToJson(this);
}

/// A single payload part inside a function response.
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class FunctionResponsePart {
  final FunctionResponseBlob? inlineData;
  final FunctionResponseFileData? fileData;

  FunctionResponsePart({this.inlineData, this.fileData});

  /// Creates an inline binary [FunctionResponsePart] by base64-encoding [data].
  factory FunctionResponsePart.fromBytes({
    required List<int> data,
    required String mimeType,
    String? displayName,
  }) => FunctionResponsePart(
    inlineData: FunctionResponseBlob.fromBytes(
      bytes: data,
      mimeType: mimeType,
      displayName: displayName,
    ),
  );

  /// Creates a URI-referenced [FunctionResponsePart] pointing to [fileUri].
  factory FunctionResponsePart.fromUri({
    required String fileUri,
    String? mimeType,
    String? displayName,
  }) => FunctionResponsePart(
    fileData: FunctionResponseFileData(
      fileUri: fileUri,
      mimeType: mimeType,
      displayName: displayName,
    ),
  );

  factory FunctionResponsePart.fromJson(Map<String, dynamic> json) {
    final rawInline = json['inline_data'] ?? json['inlineData'];
    final rawFile = json['file_data'] ?? json['fileData'];
    return _$FunctionResponsePartFromJson({
      ...json,
      if (rawInline != null)
        'inline_data': rawInline is FunctionResponseBlob
            ? rawInline.toJson()
            : rawInline,
      if (rawFile != null)
        'file_data': rawFile is FunctionResponseFileData
            ? rawFile.toJson()
            : rawFile,
    });
  }

  Map<String, dynamic> toJson() => _$FunctionResponsePartToJson(this);
}

/// A tool result sent back to the model.
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class FunctionResponse {
  final String? id;
  final String? name;
  final Map<String, dynamic>? response;
  final bool? willContinue;
  final FunctionResponseScheduling? scheduling;
  final List<FunctionResponsePart>? parts;

  FunctionResponse({
    this.id,
    this.name,
    this.response,
    this.willContinue,
    this.scheduling,
    this.parts,
  });

  factory FunctionResponse.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFromJson({
        ...json,
        if (!json.containsKey('will_continue') &&
            json.containsKey('willContinue'))
          'will_continue': json['willContinue'],
        if (json['parts'] is List)
          'parts': (json['parts'] as List)
              .map((e) => e is FunctionResponsePart ? e.toJson() : e)
              .toList(),
      });

  Map<String, dynamic> toJson() => _$FunctionResponseToJson(this);
}

/// A function schema exposed to the model as a callable tool.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionDeclaration {
  final String? description;
  final String? name;
  final Map<String, dynamic>? parameters;
  final dynamic parametersJsonSchema;
  final Map<String, dynamic>? response;
  final dynamic responseJsonSchema;
  final Behavior? behavior;

  FunctionDeclaration({
    this.description,
    this.name,
    this.parameters,
    this.parametersJsonSchema,
    this.response,
    this.responseJsonSchema,
    this.behavior,
  });

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      _$FunctionDeclarationFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionDeclarationToJson(this);
}

/// A time interval used by search filters.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Interval {
  final DateTime? startTime;
  final DateTime? endTime;

  Interval({this.startTime, this.endTime});

  factory Interval.fromJson(Map<String, dynamic> json) =>
      _$IntervalFromJson(json);

  Map<String, dynamic> toJson() => _$IntervalToJson(this);
}

/// Standard web search for grounding and related configurations.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class WebSearch {
  /// Creates a web search marker.
  const WebSearch();

  /// Creates a [WebSearch] from a JSON payload.
  factory WebSearch.fromJson(Map<String, dynamic> json) =>
      _$WebSearchFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$WebSearchToJson(this);
}

/// Image search for grounding and related configurations.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ImageSearch {
  /// Creates an image search marker.
  const ImageSearch();

  /// Creates an [ImageSearch] from a JSON payload.
  factory ImageSearch.fromJson(Map<String, dynamic> json) =>
      _$ImageSearchFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$ImageSearchToJson(this);
}

/// Different types of search that can be enabled on the [GoogleSearch] tool.
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class SearchTypes {
  /// Setting this field enables web search. Only text results are returned.
  final WebSearch? webSearch;

  /// Setting this field enables image search. Image bytes are returned.
  final ImageSearch? imageSearch;

  const SearchTypes({this.webSearch, this.imageSearch});

  factory SearchTypes.fromJson(Map<String, dynamic> json) =>
      _$SearchTypesFromJson({
        ...json,
        if (!json.containsKey('web_search') && json.containsKey('webSearch'))
          'web_search': json['webSearch'],
        if (!json.containsKey('image_search') &&
            json.containsKey('imageSearch'))
          'image_search': json['imageSearch'],
      });

  Map<String, dynamic> toJson() => _$SearchTypesToJson(this);
}

/// Google Search tool configuration.
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class GoogleSearch {
  final List<String>? excludeDomains;
  final Interval? timeRangeFilter;
  final String? blockingConfidence;

  /// The set of search types to enable. If not set, web search is enabled by default.
  final SearchTypes? searchTypes;

  const GoogleSearch({
    this.excludeDomains,
    this.timeRangeFilter,
    this.blockingConfidence,
    this.searchTypes,
  });

  factory GoogleSearch.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchFromJson({
        ...json,
        if (!json.containsKey('exclude_domains') &&
            json.containsKey('excludeDomains'))
          'exclude_domains': json['excludeDomains'],
        if (!json.containsKey('time_range_filter') &&
            json.containsKey('timeRangeFilter'))
          'time_range_filter': json['timeRangeFilter'],
        if (!json.containsKey('blocking_confidence') &&
            json.containsKey('blockingConfidence'))
          'blocking_confidence': json['blockingConfidence'],
        if (!json.containsKey('search_types') &&
            json.containsKey('searchTypes'))
          'search_types': json['searchTypes'],
      });

  Map<String, dynamic> toJson() => _$GoogleSearchToJson(this);
}

/// Dynamic retrieval thresholds for grounded search.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class DynamicRetrievalConfig {
  final double? dynamicThreshold;
  final String? mode;

  const DynamicRetrievalConfig({this.dynamicThreshold, this.mode});

  factory DynamicRetrievalConfig.fromJson(Map<String, dynamic> json) =>
      _$DynamicRetrievalConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DynamicRetrievalConfigToJson(this);
}

/// Retrieval settings for the Google Search tool.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleSearchRetrieval {
  final DynamicRetrievalConfig? dynamicRetrievalConfig;

  const GoogleSearchRetrieval({this.dynamicRetrievalConfig});

  factory GoogleSearchRetrieval.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchRetrievalFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSearchRetrievalToJson(this);
}

/// Authentication configuration for tool integrations (such as Google Maps).
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AuthConfig {
  /// API key for authenticating with the external tool API.
  final String? apiKey;

  /// Optional authentication type identifier (e.g., "API_KEY").
  final String? authType;

  const AuthConfig({this.apiKey, this.authType});

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson({
        ...json,
        if (!json.containsKey('api_key') && json.containsKey('apiKey'))
          'api_key': json['apiKey'],
        if (!json.containsKey('auth_type') && json.containsKey('authType'))
          'auth_type': json['authType'],
      });

  Map<String, dynamic> toJson() => _$AuthConfigToJson(this);
}

/// Configuration options for Google Maps grounding in [Tool].
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class GoogleMaps {
  /// Authentication config to access the Google Maps API.
  final AuthConfig? authConfig;

  /// Whether to return a widget context token in the GroundingMetadata of the response.
  final bool? enableWidget;

  /// Grounding types supported by Google Maps, e.g. "places", "routing".
  final List<String>? groundingTypes;

  const GoogleMaps({this.authConfig, this.enableWidget, this.groundingTypes});

  factory GoogleMaps.fromJson(Map<String, dynamic> json) =>
      _$GoogleMapsFromJson({
        ...json,
        if (!json.containsKey('auth_config') && json.containsKey('authConfig'))
          'auth_config': json['authConfig'],
        if (!json.containsKey('enable_widget') &&
            json.containsKey('enableWidget'))
          'enable_widget': json['enableWidget'],
        if (!json.containsKey('grounding_types') &&
            json.containsKey('groundingTypes'))
          'grounding_types': json['groundingTypes'],
      });

  Map<String, dynamic> toJson() => _$GoogleMapsToJson(this);
}

/// A transport that can stream HTTP requests and responses for an [McpServer].
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class StreamableHttpTransport {
  /// The full URL for the MCPServer endpoint (e.g., "https://api.example.com/mcp").
  final String? url;

  /// Optional authentication headers or custom metadata.
  final Map<String, String>? headers;

  /// HTTP timeout for regular operations (e.g., "30s").
  final String? timeout;

  /// Timeout for SSE read operations (e.g., "60s").
  final String? sseReadTimeout;

  /// Whether to close the client session when the transport closes.
  final bool? terminateOnClose;

  const StreamableHttpTransport({
    this.url,
    this.headers,
    this.timeout,
    this.sseReadTimeout,
    this.terminateOnClose,
  });

  factory StreamableHttpTransport.fromJson(Map<String, dynamic> json) =>
      _$StreamableHttpTransportFromJson({
        ...json,
        if (!json.containsKey('sse_read_timeout') &&
            json.containsKey('sseReadTimeout'))
          'sse_read_timeout': json['sseReadTimeout'],
        if (!json.containsKey('terminate_on_close') &&
            json.containsKey('terminateOnClose'))
          'terminate_on_close': json['terminateOnClose'],
      });

  Map<String, dynamic> toJson() => _$StreamableHttpTransportToJson(this);
}

/// An MCP server that can be called by the model to perform actions.
@JsonSerializable(
  includeIfNull: false,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
)
class McpServer {
  /// The name of the MCPServer.
  final String? name;

  /// A transport that can stream HTTP requests and responses.
  final StreamableHttpTransport? streamableHttpTransport;

  const McpServer({this.name, this.streamableHttpTransport});

  factory McpServer.fromJson(Map<String, dynamic> json) =>
      _$McpServerFromJson({
        ...json,
        if (!json.containsKey('streamable_http_transport') &&
            json.containsKey('streamableHttpTransport'))
          'streamable_http_transport': json['streamableHttpTransport'],
      });

  Map<String, dynamic> toJson() => _$McpServerToJson(this);
}

/// A tool bundle that can be attached to a model session.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Tool {
  final List<FunctionDeclaration>? functionDeclarations;
  final GoogleSearch? googleSearch;
  final GoogleSearchRetrieval? googleSearchRetrieval;
  final Map<String, dynamic>? codeExecution;
  final Map<String, dynamic>? urlContext;
  @JsonKey(fromJson: _googleMapsFromJson, toJson: _googleMapsToJson)
  final Object? googleMaps;
  final Map<String, dynamic>? retrieval;
  @JsonKey(fromJson: _computerUseFromJson, toJson: _computerUseToJson)
  final Object? computerUse;
  final Map<String, dynamic>? fileSearch;
  final Map<String, dynamic>? enterpriseWebSearch;
  final List<Map<String, dynamic>>? mcpServers;
  final ToolExaAiSearch? exaAiSearch;
  final ToolParallelAiSearch? parallelAiSearch;

  Tool({
    this.functionDeclarations,
    this.googleSearch,
    this.googleSearchRetrieval,
    this.codeExecution,
    this.urlContext,
    this.googleMaps,
    this.retrieval,
    this.computerUse,
    this.fileSearch,
    this.enterpriseWebSearch,
    this.mcpServers,
    this.exaAiSearch,
    this.parallelAiSearch,
  });

  /// Convenience factory to construct a [Tool] with typed [McpServer] definitions.
  factory Tool.fromMcpServers(List<McpServer> servers) =>
      Tool(mcpServers: servers.map((s) => s.toJson()).toList());

  /// Returns [mcpServers] parsed as typed [McpServer] instances.
  List<McpServer>? get typedMcpServers =>
      mcpServers?.map(McpServer.fromJson).toList();

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson({
    ...json,
    if (!json.containsKey('function_declarations') &&
        json.containsKey('functionDeclarations'))
      'function_declarations': (json['functionDeclarations'] as List)
          .map((e) => e is FunctionDeclaration ? e.toJson() : e)
          .toList()
    else if (json['function_declarations'] is List)
      'function_declarations': (json['function_declarations'] as List)
          .map((e) => e is FunctionDeclaration ? e.toJson() : e)
          .toList(),
  });

  Map<String, dynamic> toJson() => _$ToolToJson(this);
}

/// A tool that uses the Parallel.ai search engine for grounding.
///
/// Not supported in the Gemini Developer API.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ToolParallelAiSearch {
  final String? apiKey;
  final Map<String, dynamic>? customConfigs;

  /// Deprecated: Use [enableZeroDataRetention] instead.
  @Deprecated('Use enableZeroDataRetention instead.')
  final bool? enableDataRetention;
  final bool? enableZeroDataRetention;

  ToolParallelAiSearch({
    this.apiKey,
    this.customConfigs,
    // ignore: deprecated_member_use_from_same_package
    this.enableDataRetention,
    this.enableZeroDataRetention,
  });

  factory ToolParallelAiSearch.fromJson(Map<String, dynamic> json) =>
      _$ToolParallelAiSearchFromJson(json);

  Map<String, dynamic> toJson() => _$ToolParallelAiSearchToJson(this);
}

/// A tool that uses the Exa.ai search engine for grounding.
///
/// Not supported in the Gemini Developer API.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ToolExaAiSearch {
  final String? apiKey;
  final Map<String, dynamic>? customConfigs;

  ToolExaAiSearch({this.apiKey, this.customConfigs});

  factory ToolExaAiSearch.fromJson(Map<String, dynamic> json) =>
      _$ToolExaAiSearchFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExaAiSearchToJson(this);
}

/// Computer-use tool configuration.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ComputerUse {
  final Environment? environment;
  final List<String>? excludedPredefinedFunctions;
  final bool? enablePromptInjectionDetection;
  final List<SafetyPolicy>? disabledSafetyPolicies;

  ComputerUse({
    this.environment,
    this.excludedPredefinedFunctions,
    this.enablePromptInjectionDetection,
    this.disabledSafetyPolicies,
  });

  factory ComputerUse.fromJson(Map<String, dynamic> json) =>
      _$ComputerUseFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerUseToJson(this);
}

/// Configuration options for a [CallableTool].
class CallableToolConfig {
  /// Creates a [CallableToolConfig].
  const CallableToolConfig();

  /// Creates a [CallableToolConfig] from a JSON map.
  factory CallableToolConfig.fromJson(Map<String, dynamic> json) =>
      const CallableToolConfig();

  /// Converts this configuration to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// A tool that provides its [Tool] declaration and can execute [FunctionCall]s.
///
/// Mirrors the `CallableTool` interface in the upstream `@google/genai` SDK.
abstract class CallableTool {
  /// Returns the [Tool] declaration to include in the session setup.
  FutureOr<Tool> tool();

  /// Executes [functionCalls] and returns the resulting [Part] list.
  FutureOr<List<Part>> callTool(List<FunctionCall> functionCalls);
}


