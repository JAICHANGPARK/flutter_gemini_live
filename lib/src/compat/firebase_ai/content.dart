// API surface mirrors `package:firebase_ai` 4.x (Apache License 2.0,
// Copyright Google LLC) so that code can move between the two packages by
// swapping imports.

import 'dart:convert';
import 'dart:typed_data';

import 'live_api.dart' show MediaResolution;

/// The base structured datatype containing multi-part content of a message.
final class Content {
  // ignore: public_member_api_docs
  Content(this.role, this.parts);

  /// The producer of the content.
  ///
  /// Must be either 'user' or 'model'. Useful to set for multi-turn
  /// conversations, otherwise can be left blank or unset.
  final String? role;

  /// Ordered `Parts` that constitute a single message.
  final List<Part> parts;

  /// Return a [Content] with [TextPart].
  static Content text(String text) => Content('user', [TextPart(text)]);

  /// Return a [Content] with [InlineDataPart].
  static Content inlineData(String mimeType, Uint8List bytes,
          {MediaResolution? mediaResolution}) =>
      Content('user',
          [InlineDataPart(mimeType, bytes, mediaResolution: mediaResolution)]);

  /// Return a [Content] with multiple [Part]s.
  static Content multi(Iterable<Part> parts) => Content('user', [...parts]);

  /// Return a [Content] with multiple [Part]s from the model.
  static Content model(Iterable<Part> parts) => Content('model', [...parts]);

  /// Return a [Content] with [FunctionResponse].
  static Content functionResponse(String name, Map<String, Object?> response,
          {String? id}) =>
      Content('function', [FunctionResponse(name, response, id: id)]);

  /// Return a [Content] with multiple [FunctionResponse].
  static Content functionResponses(Iterable<FunctionResponse> responses) =>
      Content('function', responses.toList());

  /// Return a [Content] with [TextPart] of system instruction.
  static Content system(String instructions) =>
      Content('system', [TextPart(instructions)]);

  /// Convert the [Content] to json format.
  Map<String, Object?> toJson() => {
        'role': ?role,
        'parts': parts.map((p) => p.toJson()).toList(),
      };
}

/// A datatype containing media that is part of a multi-part [Content] message.
sealed class Part {
  // ignore: public_member_api_docs
  const Part({this.isThought, String? thoughtSignature})
      : _thoughtSignature = thoughtSignature;

  /// Whether this part is a thought summary.
  final bool? isThought;

  final String? _thoughtSignature;

  /// Convert the [Part] content to json format.
  Object toJson() => {
        'thought': ?isThought,
        'thoughtSignature': ?_thoughtSignature,
      };
}

/// A [Part] with an unrecognized shape, kept as raw json.
final class UnknownPart extends Part {
  // ignore: public_member_api_docs
  UnknownPart(this.data) : super(isThought: false);

  /// The unrecognized data.
  final Map<String, Object?> data;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{...superJson, ...data};
  }
}

/// A [Part] with the text content.
final class TextPart extends Part {
  // ignore: public_member_api_docs
  const TextPart(this.text, {super.isThought});

  const TextPart._(this.text, {super.isThought, super.thoughtSignature});

  /// The text content of the [Part]
  final String text;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{...superJson, 'text': text};
  }
}

/// A [Part] with the byte content of a file.
final class InlineDataPart extends Part {
  // ignore: public_member_api_docs
  const InlineDataPart(
    this.mimeType,
    this.bytes, {
    this.willContinue,
    this.mediaResolution,
    super.isThought,
  });

  const InlineDataPart._(
    this.mimeType,
    this.bytes, {
    super.isThought,
    super.thoughtSignature,
  })  : willContinue = null,
        mediaResolution = null;

  /// File type of the [InlineDataPart].
  /// https://firebase.google.com/docs/vertex-ai/input-file-requirements#supported-mime-types
  final String mimeType;

  /// Data contents in bytes.
  final Uint8List bytes;

  /// Whether there's more data coming for streaming.
  final bool? willContinue;

  /// The resolution of the media.
  final MediaResolution? mediaResolution;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'inlineData': {
        'data': base64Encode(bytes),
        'mimeType': mimeType,
        if (willContinue != null) 'willContinue': willContinue,
      },
      if (mediaResolution != null)
        'mediaResolution': {'level': mediaResolution!.toJson()},
    };
  }

  /// Converts this part to the realtime media chunk json format.
  Object toMediaChunkJson() => {
        'mimeType': mimeType,
        'data': base64Encode(bytes),
        if (willContinue != null) 'willContinue': willContinue,
      };
}

/// A predicted `FunctionCall` returned from the model that contains
/// a string representing the `FunctionDeclaration.name` with the
/// arguments and their values.
final class FunctionCall extends Part {
  // ignore: public_member_api_docs
  const FunctionCall(this.name, this.args, {this.id, super.isThought});

  const FunctionCall._(this.name, this.args,
      {this.id, super.isThought, super.thoughtSignature});

  /// The name of the function to call.
  final String name;

  /// The function parameters and values.
  final Map<String, Object?> args;

  /// The unique id of the function call.
  ///
  /// If populated, the client to execute the [FunctionCall]
  /// and return the response with the matching [id].
  final String? id;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'functionCall': {
        'name': name,
        'args': args,
        if (id != null) 'id': id,
      },
    };
  }
}

/// The response class for [FunctionCall]
final class FunctionResponse extends Part {
  // ignore: public_member_api_docs
  const FunctionResponse(this.name, this.response, {this.id, super.isThought});

  /// The name of the function that was called.
  final String name;

  /// The function response.
  ///
  /// The values must be JSON compatible types; `String`, `num`, `bool`, `List`
  /// of JSON compatible types, or `Map` from String to JSON compatible types.
  final Map<String, Object?> response;

  /// The id of the function call this response is for.
  ///
  /// Populated by the client to match the corresponding [FunctionCall.id].
  /// The Live API requires it for tool responses.
  final String? id;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'functionResponse': {
        'name': name,
        'response': response,
        if (id != null) 'id': id,
      },
    };
  }
}

/// A [Part] with Firebase Storage uri as prompt content
final class FileData extends Part {
  // ignore: public_member_api_docs
  const FileData(this.mimeType, this.fileUri,
      {this.mediaResolution, super.isThought});

  /// File type of the [FileData].
  final String mimeType;

  /// The gs:// or https:// uri of the file.
  final String fileUri;

  /// The resolution of the media.
  final MediaResolution? mediaResolution;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'file_data': {'file_uri': fileUri, 'mime_type': mimeType},
      if (mediaResolution != null)
        'mediaResolution': {'level': mediaResolution!.toJson()},
    };
  }
}

/// A [Part] that represents the code that is executed by the model.
final class ExecutableCodePart extends Part {
  // ignore: public_member_api_docs
  ExecutableCodePart({required this.language, required this.code, super.isThought});

  /// The programming language of the code.
  final CodeLanguage language;

  /// The source code to be executed.
  final String code;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'executableCode': {'language': language.toJson(), 'code': code},
    };
  }
}

/// A [Part] that represents the code execution result from the model.
final class CodeExecutionResultPart extends Part {
  // ignore: public_member_api_docs
  CodeExecutionResultPart(
      {required this.outcome, required this.output, super.isThought});

  /// The result of the execution.
  final Outcome outcome;

  /// The stdout from the code execution, or an error message if it failed.
  final String output;

  @override
  Object toJson() {
    final superJson = super.toJson() as Map<String, Object?>;
    return <String, Object?>{
      ...superJson,
      'codeExecutionResult': {'outcome': outcome.toJson(), 'output': output},
    };
  }
}

/// Supported programming languages for the generated code.
enum CodeLanguage {
  /// Unspecified status. This value should not be used.
  unspecified('LANGUAGE_UNSPECIFIED'),

  /// Python language.
  python('PYTHON');

  const CodeLanguage(this._jsonString);

  final String _jsonString;

  /// Convert to json format.
  String toJson() => _jsonString;

  /// Parse the json string to [CodeLanguage].
  static CodeLanguage parseValue(String jsonObject) => switch (jsonObject) {
        'PYTHON' => CodeLanguage.python,
        _ => CodeLanguage.unspecified,
      };
}

/// Represents the result of the code execution.
enum Outcome {
  /// Unspecified status. This value should not be used.
  unspecified('OUTCOME_UNSPECIFIED'),

  /// Code execution completed successfully.
  ok('OUTCOME_OK'),

  /// Code execution finished but with a failure. `stderr` should contain the
  /// reason.
  failed('OUTCOME_FAILED'),

  /// Code execution ran for too long, and was cancelled. There may or may not
  /// be a partial output present.
  deadlineExceeded('OUTCOME_DEADLINE_EXCEEDED');

  const Outcome(this._jsonString);

  final String _jsonString;

  /// Convert to json format.
  String toJson() => _jsonString;

  /// Parse the json string to [Outcome].
  static Outcome parseValue(String jsonObject) => switch (jsonObject) {
        'OUTCOME_OK' => Outcome.ok,
        'OUTCOME_FAILED' => Outcome.failed,
        'OUTCOME_DEADLINE_EXCEEDED' => Outcome.deadlineExceeded,
        _ => Outcome.unspecified,
      };
}

/// Internal constructors used when converting server payloads, so parts can
/// keep the thought signature that the public constructors drop.
TextPart textPartFromServer(String text,
        {bool? isThought, String? thoughtSignature}) =>
    TextPart._(text, isThought: isThought, thoughtSignature: thoughtSignature);

/// See [textPartFromServer].
InlineDataPart inlineDataPartFromServer(String mimeType, Uint8List bytes,
        {bool? isThought, String? thoughtSignature}) =>
    InlineDataPart._(mimeType, bytes,
        isThought: isThought, thoughtSignature: thoughtSignature);

/// See [textPartFromServer].
FunctionCall functionCallFromServer(String name, Map<String, Object?> args,
        {String? id, bool? isThought, String? thoughtSignature}) =>
    FunctionCall._(name, args,
        id: id, isThought: isThought, thoughtSignature: thoughtSignature);

/// Reads the thought signature of [part]; used by the core converters.
String? thoughtSignatureOf(Part part) => part._thoughtSignature;
