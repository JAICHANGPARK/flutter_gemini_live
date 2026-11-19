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

  /// How the model processes this part's media for understanding.
  ///
  /// Only meaningful for video parts ([inlineData] or [fileData] with a video
  /// MIME type). Non-video parts ignore this setting.
  final MediaProcessing? mediaProcessing;
  @JsonKey(name: 'speech_metadata')
  final SpeechMetadata? speechMetadata;

  /// Document preprocessing metadata for document [inlineData] or [fileData].
  final DocumentMetadata? documentMetadata;

  /// Spreadsheet preprocessing metadata for spreadsheet [inlineData] or
  /// [fileData].
  final SpreadsheetMetadata? spreadsheetMetadata;

  /// Audio preprocessing metadata for audio [inlineData] or [fileData].
  final AudioMetadata? audioMetadata;

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
    this.documentMetadata,
    this.spreadsheetMetadata,
    this.audioMetadata,
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
      if (!json.containsKey('mediaProcessing') &&
          json.containsKey('media_processing'))
        'mediaProcessing': json['media_processing'],
      if (!json.containsKey('documentMetadata') &&
          json.containsKey('document_metadata'))
        'documentMetadata': json['document_metadata'],
      if (!json.containsKey('spreadsheetMetadata') &&
          json.containsKey('spreadsheet_metadata'))
        'spreadsheetMetadata': json['spreadsheet_metadata'],
      if (!json.containsKey('audioMetadata') &&
          json.containsKey('audio_metadata'))
        'audioMetadata': json['audio_metadata'],
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
  /// Optional start offset of the video (for example, `'10.5s'`).
  final String? startOffset;

  /// Optional end offset of the video (for example, `'30s'`).
  final String? endOffset;

  /// Optional frame rate of the video sent to the model in `(0.0, 24.0]`.
  final double? fps;

  /// Optional content layers to extract from the video.
  ///
  /// When empty, defaults to `[FRAMES, AUDIO]`.
  final List<VideoMetadataContentLayer>? contentLayers;

  /// Creates [VideoMetadata] for video preprocessing.
  VideoMetadata({
    this.startOffset,
    this.endOffset,
    this.fps,
    this.contentLayers,
  });

  /// Creates [VideoMetadata] from a JSON map.
  factory VideoMetadata.fromJson(Map<String, dynamic> json) =>
      _$VideoMetadataFromJson({
        ...json,
        if (!json.containsKey('start_offset') &&
            json.containsKey('startOffset'))
          'start_offset': json['startOffset'],
        if (!json.containsKey('end_offset') && json.containsKey('endOffset'))
          'end_offset': json['endOffset'],
        if (!json.containsKey('content_layers') &&
            json.containsKey('contentLayers'))
          'content_layers': json['contentLayers'],
      });

  /// Serializes this [VideoMetadata] to a JSON map.
  Map<String, dynamic> toJson() => _$VideoMetadataToJson(this);
}

/// Metadata configuring static document preprocessing on [Part] or
/// [FunctionResponsePart].
class DocumentMetadata {
  /// Optional 1-indexed inclusive start page.
  final int? startPage;

  /// Optional 1-indexed inclusive end page.
  final int? endPage;

  /// Content layers to return (defaults to `[PAGE_IMAGE]` when empty).
  final List<DocumentMetadataContentLayer>? contentLayers;

  /// Creates [DocumentMetadata] for document preprocessing.
  const DocumentMetadata({this.startPage, this.endPage, this.contentLayers});

  /// Creates [DocumentMetadata] from a JSON map.
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start_page'] ?? json['startPage'];
    final rawEnd = json['end_page'] ?? json['endPage'];
    final rawLayers = json['content_layers'] ?? json['contentLayers'];
    return DocumentMetadata(
      startPage: rawStart is num ? rawStart.toInt() : null,
      endPage: rawEnd is num ? rawEnd.toInt() : null,
      contentLayers: rawLayers is List
          ? rawLayers
                .map(
                  (e) => e is DocumentMetadataContentLayer
                      ? e
                      : DocumentMetadataContentLayer.values.firstWhere(
                          (v) => v.name == e.toString().toUpperCase(),
                          orElse: () => DocumentMetadataContentLayer
                              .CONTENT_LAYER_UNSPECIFIED,
                        ),
                )
                .toList()
          : null,
    );
  }

  /// Serializes this [DocumentMetadata] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (startPage != null) 'start_page': startPage,
    if (endPage != null) 'end_page': endPage,
    if (contentLayers != null)
      'content_layers': contentLayers!.map((e) => e.name).toList(),
  };
}

/// Metadata configuring static spreadsheet preprocessing on [Part] or
/// [FunctionResponsePart].
class SpreadsheetMetadata {
  /// Range of cells to extract in A1 notation (for example, `'A1:D10'`).
  final String? visibleCells;

  /// 1-indexed index of the sheet to extract in workbook order.
  final int? sheetIndex;

  /// Content layers to return (defaults to `[DATA, FORMULAS]` when empty).
  final List<SpreadsheetMetadataContentLayer>? contentLayers;

  /// Creates [SpreadsheetMetadata] for spreadsheet preprocessing.
  const SpreadsheetMetadata({
    this.visibleCells,
    this.sheetIndex,
    this.contentLayers,
  });

  /// Creates [SpreadsheetMetadata] from a JSON map.
  factory SpreadsheetMetadata.fromJson(Map<String, dynamic> json) {
    final rawSheet = json['sheet_index'] ?? json['sheetIndex'];
    final rawLayers = json['content_layers'] ?? json['contentLayers'];
    return SpreadsheetMetadata(
      visibleCells:
          (json['visible_cells'] ?? json['visibleCells']) as String?,
      sheetIndex: rawSheet is num ? rawSheet.toInt() : null,
      contentLayers: rawLayers is List
          ? rawLayers
                .map(
                  (e) => e is SpreadsheetMetadataContentLayer
                      ? e
                      : SpreadsheetMetadataContentLayer.values.firstWhere(
                          (v) => v.name == e.toString().toUpperCase(),
                          orElse: () => SpreadsheetMetadataContentLayer
                              .CONTENT_LAYER_UNSPECIFIED,
                        ),
                )
                .toList()
          : null,
    );
  }

  /// Serializes this [SpreadsheetMetadata] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (visibleCells != null) 'visible_cells': visibleCells,
    if (sheetIndex != null) 'sheet_index': sheetIndex,
    if (contentLayers != null)
      'content_layers': contentLayers!.map((e) => e.name).toList(),
  };
}

/// Metadata configuring static audio preprocessing on [Part] or
/// [FunctionResponsePart].
class AudioMetadata {
  /// Start offset of the audio relative to the start of the stream.
  final String? startOffset;

  /// End offset of the audio relative to the start of the stream.
  final String? endOffset;

  /// Creates [AudioMetadata] for audio preprocessing.
  const AudioMetadata({this.startOffset, this.endOffset});

  /// Creates [AudioMetadata] from a JSON map.
  factory AudioMetadata.fromJson(Map<String, dynamic> json) => AudioMetadata(
    startOffset: (json['start_offset'] ?? json['startOffset']) as String?,
    endOffset: (json['end_offset'] ?? json['endOffset']) as String?,
  );

  /// Serializes this [AudioMetadata] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (startOffset != null) 'start_offset': startOffset,
    if (endOffset != null) 'end_offset': endOffset,
  };
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
