// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Data Classes - Base
// ============================================================================

/// Extra metadata associated with a content part for speech synthesis.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SpeechMetadata {
  /// The speaker for this part, which must match a `speaker` name in
  /// `MultiSpeakerVoiceConfig.speaker_voice_configs`.
  final String? speaker;

  /// The style instruction for how the voice should be synthesized
  /// (e.g. "excited, fast-paced", "whispering").
  final String? style;

  SpeechMetadata({this.speaker, this.style});

  factory SpeechMetadata.fromJson(Map<String, dynamic> json) =>
      _$SpeechMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechMetadataToJson(this);
}

/// Speech annotation for text content indicating speaker and style segment boundaries.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SpeechAnnotation {
  /// Start of segment of the response that is attributed to this source, measured in bytes.
  final int? startIndex;

  /// End of the attributed segment, exclusive, measured in bytes.
  final int? endIndex;

  /// The speaker to associate with this turn.
  final String? speaker;

  /// Style instruction for the speech synthesis.
  final String? style;

  /// Fixed type discriminator, defaults to "speech_metadata".
  final String type;

  SpeechAnnotation({
    this.startIndex,
    this.endIndex,
    this.speaker,
    this.style,
    this.type = 'speech_metadata',
  });

  factory SpeechAnnotation.fromJson(Map<String, dynamic> json) =>
      _$SpeechAnnotationFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechAnnotationToJson(this);
}

/// A single multimodal part within a content turn.
@JsonSerializable(includeIfNull: false)
class Part {
  final PartMediaResolution? mediaResolution;
  final String? text;
  final bool? thought;
  final String? thoughtSignature;
  final Blob? inlineData;
  final FileData? fileData;
  final VideoMetadata? videoMetadata;
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;
  final ToolCall? toolCall;
  final ToolResponse? toolResponse;
  final Map<String, dynamic>? partMetadata;
  final ExecutableCode? executableCode;
  final CodeExecutionResult? codeExecutionResult;
  @JsonKey(name: 'audio_transcription')
  final AudioTranscriptionConfig? audioTranscription;
  final MediaProcessing? mediaProcessing;
  @JsonKey(name: 'speech_metadata')
  final SpeechMetadata? speechMetadata;

  Part({
    this.mediaResolution,
    this.text,
    this.thought,
    this.thoughtSignature,
    this.inlineData,
    this.fileData,
    this.videoMetadata,
    this.functionCall,
    this.functionResponse,
    this.toolCall,
    this.toolResponse,
    this.partMetadata,
    this.executableCode,
    this.codeExecutionResult,
    this.audioTranscription,
    this.mediaProcessing,
    this.speechMetadata,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    final normalized = <String, dynamic>{
      ...json,
      if (!json.containsKey('inlineData') && json.containsKey('inline_data'))
        'inlineData': json['inline_data'],
      if (!json.containsKey('fileData') && json.containsKey('file_data'))
        'fileData': json['file_data'],
      if (!json.containsKey('videoMetadata') &&
          json.containsKey('video_metadata'))
        'videoMetadata': json['video_metadata'],
      if (!json.containsKey('functionCall') &&
          json.containsKey('function_call'))
        'functionCall': json['function_call'],
      if (!json.containsKey('functionResponse') &&
          json.containsKey('function_response'))
        'functionResponse': json['function_response'],
      if (!json.containsKey('mediaResolution') &&
          json.containsKey('media_resolution'))
        'mediaResolution': json['media_resolution'],
      if (!json.containsKey('thoughtSignature') &&
          json.containsKey('thought_signature'))
        'thoughtSignature': json['thought_signature'],
      if (!json.containsKey('executableCode') &&
          json.containsKey('executable_code'))
        'executableCode': json['executable_code'],
      if (!json.containsKey('codeExecutionResult') &&
          json.containsKey('code_execution_result'))
        'codeExecutionResult': json['code_execution_result'],
    };
    return _$PartFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$PartToJson(this);
}

/// Inline binary data encoded for API transport.
@JsonSerializable(includeIfNull: false)
class Blob {
  final String mimeType;
  final String data;
  final String? displayName;

  Blob({required this.mimeType, required this.data, this.displayName});

  /// Creates an inline [Blob] from raw [bytes], automatically encoding them as
  /// base64.
  factory Blob.fromBytes({
    required String mimeType,
    required List<int> bytes,
    String? displayName,
  }) =>
      Blob(
        mimeType: mimeType,
        data: base64Encode(bytes),
        displayName: displayName,
      );

  /// Decodes the base64 [data] payload into raw bytes.
  Uint8List get bytes => base64Decode(data);

  factory Blob.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final encodedData = rawData is List<int>
        ? base64Encode(rawData)
        : rawData as String;
    return _$BlobFromJson(<String, dynamic>{
      'mimeType': (json['mimeType'] ?? json['mime_type']) as String,
      'data': encodedData,
      if (json['displayName'] != null || json['display_name'] != null)
        'displayName': (json['displayName'] ?? json['display_name']) as String?,
    });
  }

  Map<String, dynamic> toJson() => _$BlobToJson(this);
}

/// URI-based media content referenced by a part.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FileData {
  final String? displayName;
  final String? fileUri;
  final String? mimeType;

  FileData({this.displayName, this.fileUri, this.mimeType});

  factory FileData.fromJson(Map<String, dynamic> json) =>
      _$FileDataFromJson(json);

  Map<String, dynamic> toJson() => _$FileDataToJson(this);
}

/// Additional video metadata attached to inline or URI-based media.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class VideoMetadata {
  final String? startOffset;
  final String? endOffset;
  final double? fps;

  VideoMetadata({this.startOffset, this.endOffset, this.fps});

  factory VideoMetadata.fromJson(Map<String, dynamic> json) =>
      _$VideoMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$VideoMetadataToJson(this);
}

/// Input media tokenization hints attached to a part.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class PartMediaResolution {
  final PartMediaResolutionLevel? level;
  final int? numTokens;

  PartMediaResolution({this.level, this.numTokens});

  factory PartMediaResolution.fromJson(Map<String, dynamic> json) =>
      _$PartMediaResolutionFromJson(json);

  Map<String, dynamic> toJson() => _$PartMediaResolutionToJson(this);
}

/// A conversational turn made of one or more [Part] values.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Content {
  final List<Part>? parts;
  final String? role;

  Content({this.parts, this.role});

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson({
        ...json,
        if (json['parts'] is List)
          'parts': (json['parts'] as List)
              .map((e) => e is Part ? e.toJson() : e)
              .toList(),
      });

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}
