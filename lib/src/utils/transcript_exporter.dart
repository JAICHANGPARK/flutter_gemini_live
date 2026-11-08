import 'dart:convert';

import '../model/models.dart';
import 'live_session_controller.dart';

/// Utilities for converting, persisting, and exporting Gemini Live conversation
/// transcripts ([LiveTranscriptItem]) into [HistoryConfig] (for seeding new
/// sessions), Markdown, JSON, WebVTT (`.vtt`), and SubRip (`.srt`) subtitles.
class GeminiLiveTranscriptExporter {
  GeminiLiveTranscriptExporter._(); // coverage:ignore-line

  /// Converts a list of [LiveTranscriptItem]s into a list of [Content] turns
  /// suitable for seeding a new Gemini Live session via `sendClientContent`
  /// (when `HistoryConfig(initialHistoryInClientContent: true)` is enabled).
  ///
  /// Empty or still-streaming partial turns can be filtered via [includeStreaming].
  static List<Content> toContentTurns(
    List<LiveTranscriptItem> transcripts, {
    bool includeStreaming = true,
  }) {
    final turns = <Content>[];
    for (final item in transcripts) {
      if (!includeStreaming && item.isStreaming) continue;
      final parts = <Part>[];
      if (item.imageBytes != null && item.imageBytes!.isNotEmpty) {
        parts.add(
          Part(
            inlineData: Blob(
              mimeType: item.imageMimeType ?? 'image/jpeg',
              data: base64Encode(item.imageBytes!),
            ),
          ),
        );
      }
      if (item.text.trim().isNotEmpty) {
        parts.add(Part(text: item.text));
      }
      if (parts.isEmpty) continue;
      turns.add(
        Content(
          role: item.role.toLowerCase() == 'user' ? 'user' : 'model',
          parts: parts,
        ),
      );
    }
    return turns;
  }

  /// Converts a list of [LiveTranscriptItem]s into a [LiveClientContent]
  /// payload ready to send after `HistoryConfig(initialHistoryInClientContent: true)`.
  static LiveClientContent toHistoryClientContent(
    List<LiveTranscriptItem> transcripts, {
    bool turnComplete = true,
    bool includeStreaming = true,
  }) {
    return LiveClientContent(
      turns: toContentTurns(transcripts, includeStreaming: includeStreaming),
      turnComplete: turnComplete,
    );
  }

  /// Exports [transcripts] to a clean Markdown document.
  static String toMarkdown(
    List<LiveTranscriptItem> transcripts, {
    String title = 'Gemini Live Transcript',
    bool includeTimestamps = true,
  }) {
    final buffer = StringBuffer('# $title\n\n');
    for (final item in transcripts) {
      final speakerLabel = item.speaker ??
          (item.role.toLowerCase() == 'user' ? 'User' : 'Gemini');
      final timePrefix = includeTimestamps
          ? '[${_formatTimeHms(item.timestamp)}] '
          : '';
      buffer.writeln('### $timePrefix**$speakerLabel**');
      if (item.text.trim().isNotEmpty) {
        buffer.writeln(item.text.trim());
      }
      if (item.imageBytes != null && item.imageBytes!.isNotEmpty) {
        buffer.writeln(
          '*(Attached image: ${item.imageMimeType ?? "image/jpeg"}, ${item.imageBytes!.length} bytes)*',
        );
      }
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  /// Serializes [transcripts] to a JSON string for local persistence.
  static String toJsonString(
    List<LiveTranscriptItem> transcripts, {
    bool pretty = false,
  }) {
    final list = transcripts
        .map(
          (item) => <String, dynamic>{
            'role': item.role,
            'text': item.text,
            if (item.speaker != null) 'speaker': item.speaker,
            if (item.style != null) 'style': item.style,
            if (item.imageBytes != null)
              'imageBase64': base64Encode(item.imageBytes!),
            if (item.imageMimeType != null) 'imageMimeType': item.imageMimeType,
            'timestamp': item.timestamp.toIso8601String(),
            'isStreaming': item.isStreaming,
          },
        )
        .toList();
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(list)
        : jsonEncode(list);
  }

  /// Deserializes a JSON string created by [toJsonString] back into a list of
  /// [LiveTranscriptItem] objects.
  static List<LiveTranscriptItem> fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as List<dynamic>;
    return decoded.map((raw) {
      final map = raw as Map<String, dynamic>;
      final imageBase64 = map['imageBase64'] as String?;
      return LiveTranscriptItem(
        role: (map['role'] as String?) ?? 'user',
        text: (map['text'] as String?) ?? '',
        speaker: map['speaker'] as String?,
        style: map['style'] as String?,
        imageBytes: imageBase64 != null ? base64Decode(imageBase64) : null,
        imageMimeType: map['imageMimeType'] as String?,
        timestamp: map['timestamp'] != null
            ? DateTime.parse(map['timestamp'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
        isStreaming: (map['isStreaming'] as bool?) ?? false,
      );
    }).toList();
  }

  /// Exports [transcripts] to WebVTT (`.vtt`) subtitle format using relative
  /// timestamps starting from the first transcript item.
  static String toWebVtt(
    List<LiveTranscriptItem> transcripts, {
    Duration defaultCueDuration = const Duration(seconds: 3),
  }) {
    final buffer = StringBuffer('WEBVTT\n\n');
    if (transcripts.isEmpty) return buffer.toString();

    final origin = transcripts.first.timestamp;
    for (int i = 0; i < transcripts.length; i++) {
      final item = transcripts[i];
      if (item.text.trim().isEmpty) continue;
      final start = item.timestamp.difference(origin);
      final safeStart = start.isNegative ? Duration.zero : start;
      final end = (i + 1 < transcripts.length)
          ? transcripts[i + 1].timestamp.difference(origin)
          : safeStart + defaultCueDuration;
      final safeEnd = end <= safeStart ? safeStart + defaultCueDuration : end;
      final speaker = item.speaker ??
          (item.role.toLowerCase() == 'user' ? 'User' : 'Gemini');

      buffer.writeln(
        '${_formatVttDuration(safeStart)} --> ${_formatVttDuration(safeEnd)}',
      );
      buffer.writeln('<v $speaker>${item.text.trim()}');
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  /// Exports [transcripts] to SubRip (`.srt`) subtitle format using relative
  /// timestamps starting from the first transcript item.
  static String toSrt(
    List<LiveTranscriptItem> transcripts, {
    Duration defaultCueDuration = const Duration(seconds: 3),
  }) {
    if (transcripts.isEmpty) return '';
    final buffer = StringBuffer();
    final origin = transcripts.first.timestamp;
    int cueIndex = 1;

    for (int i = 0; i < transcripts.length; i++) {
      final item = transcripts[i];
      if (item.text.trim().isEmpty) continue;
      final start = item.timestamp.difference(origin);
      final safeStart = start.isNegative ? Duration.zero : start;
      final end = (i + 1 < transcripts.length)
          ? transcripts[i + 1].timestamp.difference(origin)
          : safeStart + defaultCueDuration;
      final safeEnd = end <= safeStart ? safeStart + defaultCueDuration : end;
      final speaker = item.speaker ??
          (item.role.toLowerCase() == 'user' ? 'User' : 'Gemini');

      buffer.writeln('$cueIndex');
      buffer.writeln(
        '${_formatSrtDuration(safeStart)} --> ${_formatSrtDuration(safeEnd)}',
      );
      buffer.writeln('[$speaker] ${item.text.trim()}');
      buffer.writeln();
      cueIndex++;
    }
    return buffer.toString().trimRight();
  }

  static String _formatTimeHms(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String _formatVttDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  static String _formatSrtDuration(Duration d) {
    return _formatVttDuration(d).replaceAll('.', ',');
  }

  /// Returns `true` when [content] has at least one non-empty [Part].
  static bool validateContent(Content content) {
    final parts = content.parts;
    if (parts == null || parts.isEmpty) {
      return false;
    }
    for (final part in parts) {
      if (part.toJson().isEmpty) {
        return false;
      }
    }
    return true;
  }

  static bool _hasFunctionCall(Content content) =>
      (content.parts ?? const <Part>[]).any((part) => part.functionCall != null);

  static bool _hasFunctionResponse(Content content) => (content.parts ??
          const <Part>[])
      .any((part) => part.functionResponse != null);

  static void _dropRejectedInput(List<Content> curatedHistory) {
    while (curatedHistory.isNotEmpty) {
      final rejectedInput = curatedHistory.removeLast();
      if (!_hasFunctionResponse(rejectedInput)) {
        return;
      }
      var callStart = curatedHistory.length;
      while (callStart > 0 && curatedHistory[callStart - 1].role == 'model') {
        callStart -= 1;
      }
      final hasCall = curatedHistory
          .sublist(callStart)
          .any((c) => _hasFunctionCall(c));
      if (!hasCall) {
        return;
      }
      curatedHistory.removeRange(callStart, curatedHistory.length);
    }
  }

  /// Extracts the curated (valid) history from [comprehensiveHistory].
  ///
  /// Drops rejected/invalid model turns and their preceding user input. If the
  /// rejected turn's input is a function response from an automatic function
  /// calling (AFC) exchange, the entire AFC exchange back to the user input
  /// that started it is dropped.
  static List<Content> extractCuratedHistory(
    List<Content> comprehensiveHistory,
  ) {
    if (comprehensiveHistory.isEmpty) {
      return <Content>[];
    }
    final curatedHistory = <Content>[];
    final length = comprehensiveHistory.length;
    var i = 0;
    while (i < length) {
      final role = comprehensiveHistory[i].role;
      if (role != 'user' && role != 'model') {
        throw ArgumentError(
          'Role must be user or model, but got $role',
        );
      }
      if (role == 'user') {
        curatedHistory.add(comprehensiveHistory[i]);
        i += 1;
      } else {
        final currentOutput = <Content>[];
        var isValid = true;
        while (i < length && comprehensiveHistory[i].role == 'model') {
          currentOutput.add(comprehensiveHistory[i]);
          if (isValid && !validateContent(comprehensiveHistory[i])) {
            isValid = false;
          }
          i += 1;
        }
        if (isValid) {
          curatedHistory.addAll(currentOutput);
        } else {
          _dropRejectedInput(curatedHistory);
        }
      }
    }
    return curatedHistory;
  }
}
