import 'dart:convert';
import 'dart:typed_data';

import 'math_curriculum_level.dart';

/// A completed or in-progress math solution record with persistent serialization.
class MathSolutionRecord {
  final String id;
  final DateTime timestamp;
  final MathCurriculumLevel level;
  final String problemSummary;
  final String problemLevel;
  final String examinerIntent;
  final String solutionMarkdown;
  final String finalAnswer;
  final String thinkingLog;
  final Uint8List? capturedImage;

  MathSolutionRecord({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.problemSummary,
    this.problemLevel = '',
    this.examinerIntent = '',
    required this.solutionMarkdown,
    required this.finalAnswer,
    required this.thinkingLog,
    this.capturedImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'level': level.id,
    'problemSummary': problemSummary,
    'problemLevel': problemLevel,
    'examinerIntent': examinerIntent,
    'solutionMarkdown': solutionMarkdown,
    'finalAnswer': finalAnswer,
    'thinkingLog': thinkingLog,
    'capturedImage': capturedImage != null
        ? base64Encode(capturedImage!)
        : null,
  };

  factory MathSolutionRecord.fromJson(Map<String, dynamic> json) {
    return MathSolutionRecord(
      id:
          json['id'] as String? ??
          'math_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      level: MathCurriculumLevel.values.firstWhere(
        (l) => l.id == json['level'],
        orElse: () => MathCurriculumLevel.auto,
      ),
      problemSummary: json['problemSummary'] as String? ?? '',
      problemLevel: json['problemLevel'] as String? ?? '',
      examinerIntent: json['examinerIntent'] as String? ?? '',
      solutionMarkdown: json['solutionMarkdown'] as String? ?? '',
      finalAnswer: json['finalAnswer'] as String? ?? '',
      thinkingLog: json['thinkingLog'] as String? ?? '',
      capturedImage: json['capturedImage'] != null
          ? base64Decode(json['capturedImage'] as String)
          : null,
    );
  }
}
