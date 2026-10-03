// API surface mirrors `package:firebase_ai` 4.x (Apache License 2.0,
// Copyright Google LLC) so that code can move between the two packages by
// swapping imports.

import 'dart:async';

import 'schema.dart';

/// Tool details that the model may use to generate a response.
final class Tool {
  Tool._(this._functionDeclarations, this._googleSearch, this._codeExecution,
      this._urlContext, this._googleMaps);

  /// Returns a [Tool] instance with list of [FunctionDeclaration].
  static Tool functionDeclarations(
          List<FunctionDeclaration> functionDeclarations) =>
      Tool._(functionDeclarations, null, null, null, null);

  /// Creates a tool that allows the model to use Grounding with Google Search.
  static Tool googleSearch({GoogleSearch googleSearch = const GoogleSearch()}) =>
      Tool._(null, googleSearch, null, null, null);

  /// Returns a [Tool] instance that enables the model to use Code Execution.
  static Tool codeExecution(
          {CodeExecution codeExecution = const CodeExecution()}) =>
      Tool._(null, null, codeExecution, null, null);

  /// Creates a tool that allows you to provide additional context to the
  /// model in the form of public web URLs.
  static Tool urlContext({UrlContext urlContext = const UrlContext()}) =>
      Tool._(null, null, null, urlContext, null);

  /// Creates a tool that allows the model to use Grounding with Google Maps.
  static Tool googleMaps({GoogleMaps googleMaps = const GoogleMaps()}) =>
      Tool._(null, null, null, null, googleMaps);

  final List<FunctionDeclaration>? _functionDeclarations;
  final GoogleSearch? _googleSearch;
  final CodeExecution? _codeExecution;
  final UrlContext? _urlContext;
  final GoogleMaps? _googleMaps;

  /// Returns a list of all [AutoFunctionDeclaration] objects
  /// found within the [_functionDeclarations] list.
  List<AutoFunctionDeclaration> get autoFunctionDeclarations =>
      _functionDeclarations?.whereType<AutoFunctionDeclaration>().toList() ??
      [];

  /// Convert to json object.
  Map<String, Object> toJson() => {
        if (_functionDeclarations case final functionDeclarations?)
          'functionDeclarations':
              functionDeclarations.map((f) => f.toJson()).toList(),
        if (_googleSearch case final googleSearch?)
          'googleSearch': googleSearch.toJson(),
        if (_codeExecution case final codeExecution?)
          'codeExecution': codeExecution.toJson(),
        if (_urlContext case final urlContext?)
          'urlContext': urlContext.toJson(),
        if (_googleMaps case final googleMaps?)
          'googleMaps': googleMaps.toJson(),
      };
}

/// A tool that allows a Gemini model to connect to Google Search.
final class GoogleSearch {
  // ignore: public_member_api_docs
  const GoogleSearch();

  /// Convert to json object.
  Map<String, Object> toJson() => {};
}

/// A tool that allows a Gemini model to connect to Google Maps.
final class GoogleMaps {
  // ignore: public_member_api_docs
  const GoogleMaps();

  /// Convert to json object.
  Map<String, Object> toJson() => {};
}

/// A tool that allows you to provide additional context to the model in the
/// form of public web URLs.
final class UrlContext {
  // ignore: public_member_api_docs
  const UrlContext();

  /// Convert to json object.
  Map<String, Object> toJson() => {};
}

/// A tool that enables the model to use code execution.
final class CodeExecution {
  // ignore: public_member_api_docs
  const CodeExecution();

  /// Convert to json object.
  Map<String, Object> toJson() => {};
}

/// Structured representation of a function declaration as defined by the
/// [OpenAPI 3.03 specification](https://spec.openapis.org/oas/v3.0.3).
class FunctionDeclaration {
  // ignore: public_member_api_docs
  FunctionDeclaration(this.name, this.description,
      {required Map<String, Schema> parameters,
      List<String> optionalParameters = const []})
      : _schemaObject = parameters.values.any((s) => s is JSONSchema)
            ? JSONSchema.object(
                properties: parameters.cast<String, JSONSchema>(),
                optionalProperties: optionalParameters)
            : Schema.object(
                properties: parameters, optionalProperties: optionalParameters);

  /// The name of the function.
  final String name;

  /// A brief description of the function.
  final String description;

  final Schema _schemaObject;

  /// Convert to json object.
  Map<String, Object?> toJson() => {
        'name': name,
        'description': description,
        if (_schemaObject is JSONSchema)
          'parametersJsonSchema': _schemaObject.toJson()
        else
          'parameters': _schemaObject.toJson(),
      };
}

/// A [FunctionDeclaration] that carries its own implementation.
///
/// Like `firebase_ai`, the Live session does not invoke [callable]
/// automatically; answer `LiveServerToolCall`s with `LiveSession.sendToolResponse`.
final class AutoFunctionDeclaration extends FunctionDeclaration {
  // ignore: public_member_api_docs
  AutoFunctionDeclaration({
    required String name,
    required String description,
    required Map<String, Schema> parameters,
    List<String> optionalParameters = const [],
    required this.callable,
  }) : super(name, description,
            parameters: parameters, optionalParameters: optionalParameters);

  /// The function to be executed.
  final FutureOr<Map<String, Object?>> Function(Map<String, Object?> args)
      callable;
}
