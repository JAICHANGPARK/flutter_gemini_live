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

  factory FunctionResponseBlob.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseBlobFromJson(json);

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
      _$FunctionResponseFileDataFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseFileDataToJson(this);
}

/// A single payload part inside a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponsePart {
  final FunctionResponseBlob? inlineData;
  final FunctionResponseFileData? fileData;

  FunctionResponsePart({this.inlineData, this.fileData});

  factory FunctionResponsePart.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponsePartFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponsePartToJson(this);
}

/// A tool result sent back to the model.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
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
      _$FunctionResponseFromJson(json);

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

/// Google Search tool configuration.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleSearch {
  final List<String>? excludeDomains;
  final Interval? timeRangeFilter;
  final String? blockingConfidence;

  GoogleSearch({
    this.excludeDomains,
    this.timeRangeFilter,
    this.blockingConfidence,
  });

  factory GoogleSearch.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSearchToJson(this);
}

/// Dynamic retrieval thresholds for grounded search.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class DynamicRetrievalConfig {
  final double? dynamicThreshold;
  final String? mode;

  DynamicRetrievalConfig({this.dynamicThreshold, this.mode});

  factory DynamicRetrievalConfig.fromJson(Map<String, dynamic> json) =>
      _$DynamicRetrievalConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DynamicRetrievalConfigToJson(this);
}

/// Retrieval settings for the Google Search tool.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleSearchRetrieval {
  final DynamicRetrievalConfig? dynamicRetrievalConfig;

  GoogleSearchRetrieval({this.dynamicRetrievalConfig});

  factory GoogleSearchRetrieval.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchRetrievalFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSearchRetrievalToJson(this);
}

/// Configuration options for Google Maps grounding in [Tool].
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleMaps {
  /// Grounding types supported by Google Maps, e.g. "places", "routing".
  final List<String>? groundingTypes;

  GoogleMaps({this.groundingTypes});

  factory GoogleMaps.fromJson(Map<String, dynamic> json) =>
      _$GoogleMapsFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleMapsToJson(this);
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

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

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

