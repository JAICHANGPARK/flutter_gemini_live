// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Interactions Static Media Processing Models
// ============================================================================

/// Content layer identifiers extractable from video inputs in static processing.
abstract final class VideoContentLayer {
  /// Sampled video frames (`'frames'`).
  static const String frames = 'frames';

  /// Extracted audio track (`'audio'`).
  static const String audio = 'audio';

  /// Extracted speech transcript (`'transcript'`).
  static const String transcript = 'transcript';
}

/// Static video media processing options for the Interactions API.
class StaticMediaProcessing {
  /// Fixed discriminator (`'static'`).
  final String type;

  /// Optional content layers to extract (`'frames'`, `'audio'`, `'transcript'`).
  final List<String>? contentLayers;

  /// Optional segment start time relative to the video stream (e.g., `'10.5s'`).
  final String? startOffset;

  /// Optional segment end time relative to the video stream (e.g., `'30s'`).
  final String? endOffset;

  /// Optional frame-rate sampling density in frames per second.
  final double? fps;

  /// Creates [StaticMediaProcessing] options for video inputs.
  const StaticMediaProcessing({
    this.type = 'static',
    this.contentLayers,
    this.startOffset,
    this.endOffset,
    this.fps,
  });

  /// Creates [StaticMediaProcessing] from a JSON map.
  factory StaticMediaProcessing.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['content_layers'] ?? json['contentLayers'];
    final rawFps = json['fps'];
    return StaticMediaProcessing(
      type: (json['type'] as String?) ?? 'static',
      contentLayers: rawLayers is List
          ? rawLayers.map((e) => e.toString()).toList()
          : null,
      startOffset: (json['start_offset'] ?? json['startOffset']) as String?,
      endOffset: (json['end_offset'] ?? json['endOffset']) as String?,
      fps: rawFps is num ? rawFps.toDouble() : null,
    );
  }

  /// Serializes this [StaticMediaProcessing] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (contentLayers != null) 'content_layers': contentLayers,
    if (startOffset != null) 'start_offset': startOffset,
    if (endOffset != null) 'end_offset': endOffset,
    if (fps != null) 'fps': fps,
  };
}

/// Static audio media processing options for the Interactions API.
class AudioStaticMediaProcessing {
  /// Fixed discriminator (`'static'`).
  final String type;

  /// Optional segment start time relative to the start of the audio stream
  /// (for example, `'10.5s'`).
  final String? startOffset;

  /// Optional segment end time relative to the start of the audio stream
  /// (for example, `'30s'`).
  final String? endOffset;

  /// Creates [AudioStaticMediaProcessing] options for audio inputs.
  const AudioStaticMediaProcessing({
    this.type = 'static',
    this.startOffset,
    this.endOffset,
  });

  /// Creates [AudioStaticMediaProcessing] from a JSON map.
  factory AudioStaticMediaProcessing.fromJson(Map<String, dynamic> json) =>
      AudioStaticMediaProcessing(
        type: (json['type'] as String?) ?? 'static',
        startOffset: (json['start_offset'] ?? json['startOffset']) as String?,
        endOffset: (json['end_offset'] ?? json['endOffset']) as String?,
      );

  /// Serializes this [AudioStaticMediaProcessing] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (startOffset != null) 'start_offset': startOffset,
    if (endOffset != null) 'end_offset': endOffset,
  };
}

/// Content layer identifiers extractable from paginated documents.
abstract final class PageContentLayer {
  /// Rendered page image layer (`'page_image'`).
  static const String pageImage = 'page_image';

  /// Extracted page text layer (`'page_text'`).
  static const String pageText = 'page_text';
}

/// Processing options for paginated documents such as PDFs, Office documents,
/// and presentations.
class PageProcessingOptions {
  /// Optional content layers to extract (`'page_image'`, `'page_text'`).
  final List<String>? contentLayers;

  /// Optional 1-indexed inclusive start page.
  final int? startPage;

  /// Optional 1-indexed inclusive end page (must be `>= startPage` if set).
  final int? endPage;

  /// Creates [PageProcessingOptions] for paginated documents.
  const PageProcessingOptions({
    this.contentLayers,
    this.startPage,
    this.endPage,
  });

  /// Creates [PageProcessingOptions] from a JSON map.
  factory PageProcessingOptions.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['content_layers'] ?? json['contentLayers'];
    final rawStart = json['start_page'] ?? json['startPage'];
    final rawEnd = json['end_page'] ?? json['endPage'];
    return PageProcessingOptions(
      contentLayers: rawLayers is List
          ? rawLayers.map((e) => e.toString()).toList()
          : null,
      startPage: rawStart is num ? rawStart.toInt() : null,
      endPage: rawEnd is num ? rawEnd.toInt() : null,
    );
  }

  /// Serializes this [PageProcessingOptions] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (contentLayers != null) 'content_layers': contentLayers,
    if (startPage != null) 'start_page': startPage,
    if (endPage != null) 'end_page': endPage,
  };
}

/// Content layer identifiers extractable from spreadsheets.
abstract final class SpreadsheetContentLayer {
  /// Visual sheet rendering layer (`'visual'`).
  static const String visual = 'visual';

  /// Cell values data layer (`'data'`).
  static const String data = 'data';

  /// Cell formulas layer (`'formulas'`).
  static const String formulas = 'formulas';
}

/// Processing options for spreadsheets in the Interactions API.
class SpreadsheetProcessingOptions {
  /// Optional content layers to extract (`'visual'`, `'data'`, `'formulas'`).
  final List<String>? contentLayers;

  /// Optional 1-indexed sheet index in workbook order.
  ///
  /// When omitted, all sheets are extracted.
  final int? sheetIndex;

  /// Optional range of cells to extract in A1 notation (for example, `'A1:D10'`).
  final String? visibleCells;

  /// Creates [SpreadsheetProcessingOptions] for spreadsheets.
  const SpreadsheetProcessingOptions({
    this.contentLayers,
    this.sheetIndex,
    this.visibleCells,
  });

  /// Creates [SpreadsheetProcessingOptions] from a JSON map.
  factory SpreadsheetProcessingOptions.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['content_layers'] ?? json['contentLayers'];
    final rawSheet = json['sheet_index'] ?? json['sheetIndex'];
    return SpreadsheetProcessingOptions(
      contentLayers: rawLayers is List
          ? rawLayers.map((e) => e.toString()).toList()
          : null,
      sheetIndex: rawSheet is num ? rawSheet.toInt() : null,
      visibleCells:
          (json['visible_cells'] ?? json['visibleCells']) as String?,
    );
  }

  /// Serializes this [SpreadsheetProcessingOptions] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (contentLayers != null) 'content_layers': contentLayers,
    if (sheetIndex != null) 'sheet_index': sheetIndex,
    if (visibleCells != null) 'visible_cells': visibleCells,
  };
}

/// Static document media processing options for paginated documents and
/// spreadsheets in the Interactions API.
class DocumentStaticMediaProcessing {
  /// Fixed discriminator (`'static'`).
  final String type;

  /// Optional processing options for paginated documents (PDFs, Office docs,
  /// and presentations).
  final PageProcessingOptions? pageOptions;

  /// Optional processing options for spreadsheets.
  final SpreadsheetProcessingOptions? spreadsheetOptions;

  /// Creates [DocumentStaticMediaProcessing] options for document inputs.
  const DocumentStaticMediaProcessing({
    this.type = 'static',
    this.pageOptions,
    this.spreadsheetOptions,
  });

  /// Creates [DocumentStaticMediaProcessing] from a JSON map.
  factory DocumentStaticMediaProcessing.fromJson(Map<String, dynamic> json) {
    final rawPage = json['page_options'] ?? json['pageOptions'];
    final rawSpreadsheet =
        json['spreadsheet_options'] ?? json['spreadsheetOptions'];
    return DocumentStaticMediaProcessing(
      type: (json['type'] as String?) ?? 'static',
      pageOptions: rawPage is Map
          ? PageProcessingOptions.fromJson(Map<String, dynamic>.from(rawPage))
          : null,
      spreadsheetOptions: rawSpreadsheet is Map
          ? SpreadsheetProcessingOptions.fromJson(
              Map<String, dynamic>.from(rawSpreadsheet),
            )
          : null,
    );
  }

  /// Serializes this [DocumentStaticMediaProcessing] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (pageOptions != null) 'page_options': pageOptions!.toJson(),
    if (spreadsheetOptions != null)
      'spreadsheet_options': spreadsheetOptions!.toJson(),
  };
}

// ============================================================================
// Interactions Tool Search & Deferred Function Loading Models
// ============================================================================

/// Execution mode for an Interactions [ToolSearch] tool.
abstract final class ToolSearchExecution {
  /// Server-managed tool search execution (`'server'`).
  static const String server = 'server';

  /// Client-managed tool search execution (`'client'`).
  static const String client = 'client';
}

/// An Interactions API function tool definition supporting deferred loading.
class InteractionFunction {
  /// Fixed discriminator (`'function'`).
  final String type;

  /// Function identifier.
  final String? name;

  /// Full description of the function.
  final String? description;

  /// Brief summary shown to the model when [deferLoading] is `true`.
  final String? shortDescription;

  /// Whether loading of the full function schema is deferred until requested
  /// via [ToolSearch].
  final bool? deferLoading;

  /// JSON Schema describing the function parameters.
  final Object? parameters;

  /// Creates an [InteractionFunction] definition.
  const InteractionFunction({
    this.type = 'function',
    this.name,
    this.description,
    this.shortDescription,
    this.deferLoading,
    this.parameters,
  });

  /// Creates an [InteractionFunction] from a JSON map.
  factory InteractionFunction.fromJson(Map<String, dynamic> json) =>
      InteractionFunction(
        type: (json['type'] as String?) ?? 'function',
        name: json['name'] as String?,
        description: json['description'] as String?,
        shortDescription:
            (json['short_description'] ?? json['shortDescription']) as String?,
        deferLoading:
            (json['defer_loading'] ?? json['deferLoading']) as bool?,
        parameters: json['parameters'],
      );

  /// Serializes this [InteractionFunction] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (shortDescription != null) 'short_description': shortDescription,
    if (deferLoading != null) 'defer_loading': deferLoading,
    if (parameters != null) 'parameters': parameters,
  };
}

/// A tool that allows the model to dynamically search for and load deferred
/// tool definitions into context on demand.
class ToolSearch {
  /// Fixed discriminator (`'tool_search'`).
  final String type;

  /// Execution mode (`'server'` or `'client'`).
  final String? execution;

  /// Function name (set only for client-side execution).
  final String? name;

  /// Function description (set only for client-side execution).
  final String? description;

  /// JSON Schema for the search function's parameters (client-side execution).
  final Object? parameters;

  /// Creates a [ToolSearch] configuration.
  const ToolSearch({
    this.type = 'tool_search',
    this.execution,
    this.name,
    this.description,
    this.parameters,
  });

  /// Creates a [ToolSearch] from a JSON map.
  factory ToolSearch.fromJson(Map<String, dynamic> json) => ToolSearch(
    type: (json['type'] as String?) ?? 'tool_search',
    execution: json['execution'] as String?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    parameters: json['parameters'],
  );

  /// Serializes this [ToolSearch] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (execution != null) 'execution': execution,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (parameters != null) 'parameters': parameters,
  };
}

/// Arguments passed to a [ToolSearchCallStep] or [ToolSearchCallDelta].
class ToolSearchCallArguments {
  /// Explicit list of function names requested to be loaded into context.
  final List<String>? functionNames;

  /// Creates [ToolSearchCallArguments].
  const ToolSearchCallArguments({this.functionNames});

  /// Creates [ToolSearchCallArguments] from a JSON map.
  factory ToolSearchCallArguments.fromJson(Map<String, dynamic> json) {
    final rawNames = json['function_names'] ?? json['functionNames'];
    return ToolSearchCallArguments(
      functionNames: rawNames is List
          ? rawNames.map((e) => e.toString()).toList()
          : null,
    );
  }

  /// Serializes this [ToolSearchCallArguments] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (functionNames != null) 'function_names': functionNames,
  };
}

/// Completed Interactions step representing a dynamic tool search invocation.
class ToolSearchCallStep {
  /// Fixed discriminator (`'tool_search_call'`).
  final String type;

  /// Unique identifier for this tool search call.
  final String id;

  /// Arguments specifying which functions to load.
  final ToolSearchCallArguments arguments;

  /// Optional backend validation signature hash.
  final String? signature;

  /// Creates a [ToolSearchCallStep].
  const ToolSearchCallStep({
    this.type = 'tool_search_call',
    required this.id,
    required this.arguments,
    this.signature,
  });

  /// Creates a [ToolSearchCallStep] from a JSON map.
  factory ToolSearchCallStep.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['arguments'];
    return ToolSearchCallStep(
      type: (json['type'] as String?) ?? 'tool_search_call',
      id: json['id'] as String,
      arguments: rawArgs is Map
          ? ToolSearchCallArguments.fromJson(
              Map<String, dynamic>.from(rawArgs),
            )
          : const ToolSearchCallArguments(),
      signature: json['signature'] as String?,
    );
  }

  /// Serializes this [ToolSearchCallStep] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'id': id,
    'arguments': arguments.toJson(),
    if (signature != null) 'signature': signature,
  };
}

/// Completed Interactions step containing retrieved function definitions for a
/// [ToolSearchCallStep].
class ToolSearchResultStep {
  /// Fixed discriminator (`'tool_search_result'`).
  final String type;

  /// Identifier matching [ToolSearchCallStep.id].
  final String callId;

  /// Retrieved [InteractionFunction] definitions loaded into context.
  final List<InteractionFunction>? result;

  /// Optional backend validation signature hash.
  final String? signature;

  /// Creates a [ToolSearchResultStep].
  const ToolSearchResultStep({
    this.type = 'tool_search_result',
    required this.callId,
    this.result,
    this.signature,
  });

  /// Creates a [ToolSearchResultStep] from a JSON map.
  factory ToolSearchResultStep.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    return ToolSearchResultStep(
      type: (json['type'] as String?) ?? 'tool_search_result',
      callId: (json['call_id'] ?? json['callId']) as String,
      result: rawResult is List
          ? rawResult
                .whereType<Map>()
                .map(
                  (e) =>
                      InteractionFunction.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : null,
      signature: json['signature'] as String?,
    );
  }

  /// Serializes this [ToolSearchResultStep] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'call_id': callId,
    if (result != null) 'result': result!.map((e) => e.toJson()).toList(),
    if (signature != null) 'signature': signature,
  };
}

/// Incremental streaming delta for a [ToolSearchCallStep].
class ToolSearchCallDelta {
  /// Fixed discriminator (`'tool_search_call'`).
  final String type;

  /// Partial or complete tool search call arguments.
  final ToolSearchCallArguments? arguments;

  /// Optional backend validation signature hash.
  final String? signature;

  /// Creates a [ToolSearchCallDelta].
  const ToolSearchCallDelta({
    this.type = 'tool_search_call',
    this.arguments,
    this.signature,
  });

  /// Creates a [ToolSearchCallDelta] from a JSON map.
  factory ToolSearchCallDelta.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['arguments'];
    return ToolSearchCallDelta(
      type: (json['type'] as String?) ?? 'tool_search_call',
      arguments: rawArgs is Map
          ? ToolSearchCallArguments.fromJson(
              Map<String, dynamic>.from(rawArgs),
            )
          : null,
      signature: json['signature'] as String?,
    );
  }

  /// Serializes this [ToolSearchCallDelta] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (arguments != null) 'arguments': arguments!.toJson(),
    if (signature != null) 'signature': signature,
  };
}

/// Incremental streaming delta for a [ToolSearchResultStep].
class ToolSearchResultDelta {
  /// Fixed discriminator (`'tool_search_result'`).
  final String type;

  /// Retrieved [InteractionFunction] definitions emitted in this delta.
  final List<InteractionFunction>? result;

  /// Optional backend validation signature hash.
  final String? signature;

  /// Creates a [ToolSearchResultDelta].
  const ToolSearchResultDelta({
    this.type = 'tool_search_result',
    this.result,
    this.signature,
  });

  /// Creates a [ToolSearchResultDelta] from a JSON map.
  factory ToolSearchResultDelta.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    return ToolSearchResultDelta(
      type: (json['type'] as String?) ?? 'tool_search_result',
      result: rawResult is List
          ? rawResult
                .whereType<Map>()
                .map(
                  (e) =>
                      InteractionFunction.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : null,
      signature: json['signature'] as String?,
    );
  }

  /// Serializes this [ToolSearchResultDelta] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    if (result != null) 'result': result!.map((e) => e.toJson()).toList(),
    if (signature != null) 'signature': signature,
  };
}

// ============================================================================
// Recursive JSON Schema Processor ($defs / $ref)
// ============================================================================

/// Normalizes JSON Schema maps (including `$defs`, `$ref`, nullable `anyOf`
/// unions, and `property_ordering`) into Gemini API-compatible schema payloads.
abstract final class JsonSchemaTransformer {
  /// Processes [schema] in place, resolving `$defs` and `$ref` definitions per
  /// recursion path so shared union branches stay intact and cyclic back-edges
  /// terminate cleanly as `{}`.
  static void processSchema(
    Map<String, dynamic> schema, {
    bool orderProperties = true,
  }) {
    _processSchemaInternal(
      schema,
      defs: null,
      orderProperties: orderProperties,
      visitedMapsPath: Set<Map<String, dynamic>>.identity(),
      visitedRefs: <String>{},
    );
  }

  static void _processSchemaInternal(
    Map<String, dynamic> schema, {
    required Map<String, dynamic>? defs,
    required bool orderProperties,
    required Set<Map<String, dynamic>> visitedMapsPath,
    required Set<String> visitedRefs,
  }) {
    if (visitedMapsPath.contains(schema)) {
      return;
    }
    visitedMapsPath.add(schema);

    const fieldAliases = <(String, String)>[
      ('additional_properties', 'additionalProperties'),
      ('any_of', 'anyOf'),
      ('prefix_items', 'prefixItems'),
      ('property_ordering', 'propertyOrdering'),
    ];
    for (final (fromName, toName) in fieldAliases) {
      if (schema.containsKey(fromName)) {
        final value = schema.remove(fromName);
        if (value != null) {
          schema[toName] = value;
        }
      }
    }

    var effectiveDefs = defs;
    if (effectiveDefs == null) {
      final rawDefs = schema.remove(r'$defs');
      effectiveDefs = rawDefs is Map
          ? Map<String, dynamic>.from(rawDefs)
          : <String, dynamic>{};
    }

    Map<String, dynamic>? resolveRef(String ref) {
      final refName = ref.split('defs/').last;
      if (visitedRefs.contains(refName)) {
        return null;
      }
      final target = effectiveDefs![refName];
      if (target is! Map) {
        return null;
      }
      final refSchema = _deepCopyMap(Map<String, dynamic>.from(target));
      visitedRefs.add(refName);
      try {
        _processSchemaInternal(
          refSchema,
          defs: effectiveDefs,
          orderProperties: orderProperties,
          visitedMapsPath: visitedMapsPath,
          visitedRefs: visitedRefs,
        );
      } finally {
        visitedRefs.remove(refName);
      }
      return refSchema;
    }

    _handleNullFields(schema);

    final directRef = schema.remove(r'$ref');
    if (directRef is String) {
      final resolved = resolveRef(directRef);
      if (resolved != null) {
        schema.addAll(resolved);
      }
      visitedMapsPath.remove(schema);
      return;
    }

    Map<String, dynamic> recurse(Map<String, dynamic> subSchema) {
      final subRef = subSchema.remove(r'$ref');
      if (subRef is String) {
        final resolved = resolveRef(subRef);
        if (resolved == null) {
          return subSchema.isEmpty ? <String, dynamic>{} : subSchema;
        }
        return <String, dynamic>{...subSchema, ...resolved};
      }
      if (visitedMapsPath.contains(subSchema)) {
        return <String, dynamic>{};
      }
      _processSchemaInternal(
        subSchema,
        defs: effectiveDefs,
        orderProperties: orderProperties,
        visitedMapsPath: visitedMapsPath,
        visitedRefs: visitedRefs,
      );
      return subSchema;
    }

    final rawAnyOf = schema['anyOf'];
    if (rawAnyOf is List) {
      schema['anyOf'] = rawAnyOf
          .map(
            (item) => item is Map
                ? recurse(Map<String, dynamic>.from(item))
                : item,
          )
          .toList();
      visitedMapsPath.remove(schema);
      return;
    }

    final rawType = schema['type'];
    final schemaType = rawType is String ? rawType.toUpperCase() : null;

    if (schema.containsKey('const')) {
      final constValue = schema['const'];
      if (constValue != null) {
        if (schemaType == 'STRING') {
          schema['enum'] = <Object>[constValue];
          schema.remove('const');
        } else {
          throw ArgumentError.value(
            constValue,
            'const',
            'Literal const schema values must have STRING type.',
          );
        }
      }
    }

    if (schemaType == 'OBJECT') {
      final rawProps = schema['properties'];
      if (rawProps is Map) {
        final props = rawProps is Map<String, dynamic>
            ? rawProps
            : Map<String, dynamic>.from(rawProps);
        schema['properties'] = props;
        for (final key in props.keys.toList()) {
          final sub = props[key];
          if (sub is Map) {
            props[key] = recurse(
              sub is Map<String, dynamic> ? sub : Map<String, dynamic>.from(sub),
            );
          }
        }
        if (props.length > 1 &&
            orderProperties &&
            !schema.containsKey('propertyOrdering') &&
            !schema.containsKey('property_ordering')) {
          schema['property_ordering'] = props.keys.toList();
        }
      }
      final additional = schema['additionalProperties'];
      if (additional is Map) {
        schema['additionalProperties'] = recurse(
          additional is Map<String, dynamic>
              ? additional
              : Map<String, dynamic>.from(additional),
        );
      }
    } else if (schemaType == 'ARRAY') {
      final rawItems = schema['items'];
      if (rawItems is Map) {
        schema['items'] = recurse(
          rawItems is Map<String, dynamic>
              ? rawItems
              : Map<String, dynamic>.from(rawItems),
        );
      }
      final rawPrefixItems = schema['prefixItems'];
      if (rawPrefixItems is List) {
        schema['prefixItems'] = rawPrefixItems
            .map(
              (item) => item is Map
                  ? recurse(Map<String, dynamic>.from(item))
                  : item,
            )
            .toList();
      }
    }

    visitedMapsPath.remove(schema);
  }

  static void _handleNullFields(Map<String, dynamic> schema) {
    final rawType = schema['type'];
    if (rawType is String && rawType.toLowerCase() == 'null') {
      schema['nullable'] = true;
      schema.remove('type');
      return;
    }
    if (rawType is List) {
      final filtered = rawType
          .where((t) => !(t is String && t.toLowerCase() == 'null'))
          .toList();
      if (filtered.length != rawType.length) {
        schema['nullable'] = true;
        if (filtered.isEmpty) {
          schema.remove('type');
        } else if (filtered.length == 1) {
          schema['type'] = filtered.single;
        } else {
          schema['type'] = filtered;
        }
      }
    }
    final rawAnyOf = schema['anyOf'];
    if (rawAnyOf is List) {
      final nonNullItems = <dynamic>[];
      var foundNull = false;
      for (final item in rawAnyOf) {
        if (item is Map &&
            item.length == 1 &&
            item['type'] is String &&
            (item['type'] as String).toLowerCase() == 'null') {
          foundNull = true;
        } else {
          nonNullItems.add(item);
        }
      }
      if (foundNull) {
        schema['nullable'] = true;
        if (nonNullItems.length == 1 && nonNullItems.single is Map) {
          final single = Map<String, dynamic>.from(nonNullItems.single as Map);
          schema.remove('anyOf');
          schema.addAll(single);
        } else {
          schema['anyOf'] = nonNullItems;
        }
      }
    }
  }

  static Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    for (final entry in source.entries) {
      copy[entry.key] = _deepCopyValue(entry.value);
    }
    return copy;
  }

  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map) {
      return _deepCopyMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_deepCopyValue).toList();
    }
    return value;
  }
}
