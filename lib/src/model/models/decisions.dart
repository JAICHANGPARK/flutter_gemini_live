// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Decisions API Models
// ============================================================================

/// Criteria descriptions for the `true` and `false` outcomes of a [NoulQuestion].
class NoulCriteria {
  /// Optional criteria or description for the `true` outcome.
  final String? trueDescription;

  /// Optional criteria or description for the `false` outcome.
  final String? falseDescription;

  /// Creates [NoulCriteria] for binary outcome descriptions.
  const NoulCriteria({this.trueDescription, this.falseDescription});

  /// Creates [NoulCriteria] from a JSON map.
  factory NoulCriteria.fromJson(Map<String, dynamic> json) => NoulCriteria(
    trueDescription:
        (json['true_description'] ?? json['trueDescription']) as String?,
    falseDescription:
        (json['false_description'] ?? json['falseDescription']) as String?,
  );

  /// Serializes this [NoulCriteria] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (trueDescription != null) 'true_description': trueDescription,
    if (falseDescription != null) 'false_description': falseDescription,
  };
}

/// Base class for a single structured decision question in [CreateDecisionRequest].
sealed class DecisionQuestion {
  /// Creates a [DecisionQuestion].
  const DecisionQuestion();

  /// Discriminator identifying the question kind (`'noul'`, `'choice'`, or `'score'`).
  String get type;

  /// Human-readable decision guidelines, rubrics, or criteria evaluated against
  /// the shared input (`String`, `Map<String, dynamic>`, or `List<Map<String, dynamic>>`).
  Object get instructions;

  /// Parses a [DecisionQuestion] subclass from a JSON map based on `type`.
  factory DecisionQuestion.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    return switch (rawType) {
      'noul' => NoulQuestion.fromJson(json),
      'choice' => ChoiceQuestion.fromJson(json),
      'score' => ScoreQuestion.fromJson(json),
      _ => throw ArgumentError.value(
        rawType,
        'type',
        "Expected 'noul', 'choice', or 'score'.",
      ),
    };
  }

  /// Serializes this [DecisionQuestion] to a JSON map.
  Map<String, dynamic> toJson();
}

/// A binary (`true` / `false`) decision question.
final class NoulQuestion extends DecisionQuestion {
  @override
  final Object instructions;

  /// Optional criteria descriptions for the `true` and `false` outcomes.
  final NoulCriteria? criteria;

  /// Creates a binary [NoulQuestion].
  const NoulQuestion({required this.instructions, this.criteria});

  @override
  String get type => 'noul';

  /// Creates a [NoulQuestion] from a JSON map.
  factory NoulQuestion.fromJson(Map<String, dynamic> json) => NoulQuestion(
    instructions: json['instructions'] as Object,
    criteria: json['criteria'] == null
        ? null
        : NoulCriteria.fromJson(json['criteria'] as Map<String, dynamic>),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'instructions': instructions,
    if (criteria != null) 'criteria': criteria!.toJson(),
  };
}

/// A single-select categorical decision question over mutually exclusive options.
final class ChoiceQuestion extends DecisionQuestion {
  @override
  final Object instructions;

  /// Mutually exclusive options mapping option IDs to rubric descriptions.
  ///
  /// An empty string `''` indicates no description for that option ID.
  final Map<String, String> criteria;

  /// Creates a categorical [ChoiceQuestion].
  const ChoiceQuestion({required this.instructions, required this.criteria});

  @override
  String get type => 'choice';

  /// Creates a [ChoiceQuestion] from a JSON map.
  factory ChoiceQuestion.fromJson(Map<String, dynamic> json) => ChoiceQuestion(
    instructions: json['instructions'] as Object,
    criteria: (json['criteria'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'instructions': instructions,
    'criteria': criteria,
  };
}

/// A quantitative rubric scoring question over discrete numeric levels.
final class ScoreQuestion extends DecisionQuestion {
  @override
  final Object instructions;

  /// Discrete 0-based rubric level descriptions (between 2 and 255 levels).
  final List<String> criteria;

  /// Creates a rubric [ScoreQuestion].
  const ScoreQuestion({required this.instructions, required this.criteria});

  @override
  String get type => 'score';

  /// Creates a [ScoreQuestion] from a JSON map.
  factory ScoreQuestion.fromJson(Map<String, dynamic> json) => ScoreQuestion(
    instructions: json['instructions'] as Object,
    criteria: (json['criteria'] as List<dynamic>).cast<String>(),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'instructions': instructions,
    'criteria': criteria,
  };
}

/// Base class for a calibrated decision answer in [CreateDecisionResponse].
sealed class DecisionAnswer {
  /// Creates a [DecisionAnswer].
  const DecisionAnswer();

  /// Discriminator identifying the answer kind (`'noul'`, `'choice'`, or `'score'`).
  String get type;

  /// Closed-world confidence score in `[0, 1]` equal to the calibrated
  /// probability of the winning outcome.
  double get confidence;

  /// Parses a [DecisionAnswer] subclass from a JSON map based on `type`.
  factory DecisionAnswer.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    return switch (rawType) {
      'noul' => NoulAnswer.fromJson(json),
      'choice' => ChoiceAnswer.fromJson(json),
      'score' => ScoreAnswer.fromJson(json),
      _ => throw ArgumentError.value(
        rawType,
        'type',
        "Expected 'noul', 'choice', or 'score'.",
      ),
    };
  }

  /// Serializes this [DecisionAnswer] to a JSON map.
  Map<String, dynamic> toJson();
}

/// Calibrated result for a [NoulQuestion].
final class NoulAnswer extends DecisionAnswer {
  /// Calibrated probability `P(true)` in `[0.01, 0.99]`.
  final double noul;

  @override
  final double confidence;

  /// Creates a [NoulAnswer].
  const NoulAnswer({required this.noul, required this.confidence});

  @override
  String get type => 'noul';

  /// Creates a [NoulAnswer] from a JSON map.
  factory NoulAnswer.fromJson(Map<String, dynamic> json) => NoulAnswer(
    noul: (json['noul'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'noul': noul,
    'confidence': confidence,
  };
}

/// Calibrated result for a [ChoiceQuestion].
final class ChoiceAnswer extends DecisionAnswer {
  /// The option ID with the highest calibrated probability.
  final String choice;

  @override
  final double confidence;

  /// Closed-world normalized probability in `[0, 1]` for each option ID.
  final Map<String, double> probabilities;

  /// Creates a [ChoiceAnswer].
  const ChoiceAnswer({
    required this.choice,
    required this.confidence,
    required this.probabilities,
  });

  @override
  String get type => 'choice';

  /// Creates a [ChoiceAnswer] from a JSON map.
  factory ChoiceAnswer.fromJson(Map<String, dynamic> json) => ChoiceAnswer(
    choice: json['choice'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    probabilities: (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'choice': choice,
    'confidence': confidence,
    'probabilities': probabilities,
  };
}

/// Calibrated result for a [ScoreQuestion].
final class ScoreAnswer extends DecisionAnswer {
  /// Probability-weighted expected score across rubric levels.
  final double score;

  @override
  final double confidence;

  /// Closed-world normalized probability in `[0, 1]` for each 0-based level index.
  final Map<String, double> probabilities;

  /// Rubric description for each non-empty 0-based level index.
  final Map<String, String> legend;

  /// Creates a [ScoreAnswer].
  const ScoreAnswer({
    required this.score,
    required this.confidence,
    required this.probabilities,
    required this.legend,
  });

  @override
  String get type => 'score';

  /// Creates a [ScoreAnswer] from a JSON map.
  factory ScoreAnswer.fromJson(Map<String, dynamic> json) => ScoreAnswer(
    score: (json['score'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    probabilities: (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
    legend: (json['legend'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
  );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'score': score,
    'confidence': confidence,
    'probabilities': probabilities,
    'legend': legend,
  };
}

/// Reasons a decision input was blocked by content filters.
enum DecisionBlockReason {
  /// Blocked due to safety policies (`'safety'`).
  SAFETY('safety'),

  /// Blocked for an unspecified reason (`'other'`).
  OTHER('other'),

  /// Blocked due to a configured blocklist (`'blocklist'`).
  BLOCKLIST('blocklist'),

  /// Blocked due to prohibited content (`'prohibited_content'`).
  PROHIBITED_CONTENT('prohibited_content'),

  /// Blocked due to image safety policies (`'image_safety'`).
  IMAGE_SAFETY('image_safety');

  const DecisionBlockReason(this.value);

  /// Lowercase wire representation of this [DecisionBlockReason].
  final String value;

  /// Parses a [DecisionBlockReason] from a wire string (case-insensitive).
  static DecisionBlockReason fromJson(String raw) =>
      switch (raw.toLowerCase()) {
        'safety' => DecisionBlockReason.SAFETY,
        'other' => DecisionBlockReason.OTHER,
        'blocklist' => DecisionBlockReason.BLOCKLIST,
        'prohibited_content' => DecisionBlockReason.PROHIBITED_CONTENT,
        'image_safety' => DecisionBlockReason.IMAGE_SAFETY,
        _ => DecisionBlockReason.OTHER,
      };

  /// Returns the lowercase wire representation.
  String toJson() => value;
}

/// Input content filter feedback returned in [CreateDecisionResponse].
class DecisionPromptFeedback {
  /// Reason the input was blocked when no answers are returned.
  final DecisionBlockReason? blockReason;

  /// Optional human-readable explanation detailing why the input was blocked.
  final String? blockReasonMessage;

  /// Creates a [DecisionPromptFeedback].
  const DecisionPromptFeedback({this.blockReason, this.blockReasonMessage});

  /// Creates a [DecisionPromptFeedback] from a JSON map.
  factory DecisionPromptFeedback.fromJson(Map<String, dynamic> json) {
    final rawReason = (json['block_reason'] ?? json['blockReason']) as String?;
    return DecisionPromptFeedback(
      blockReason: rawReason == null
          ? null
          : DecisionBlockReason.fromJson(rawReason),
      blockReasonMessage:
          (json['block_reason_message'] ?? json['blockReasonMessage'])
              as String?,
    );
  }

  /// Serializes this [DecisionPromptFeedback] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (blockReason != null) 'block_reason': blockReason!.toJson(),
    if (blockReasonMessage != null) 'block_reason_message': blockReasonMessage,
  };
}

/// Request payload for evaluating structured decision questions against shared input.
class CreateDecisionRequest {
  /// Model identifier used to evaluate the decisions (for example `'decisions-prerelease'`).
  final String model;

  /// Shared input prefix evaluated once across all [questions] (`String`,
  /// `Map<String, dynamic>`, or `List<Object>`).
  final Object input;

  /// Structured decision questions keyed by caller-defined question identifiers.
  final Map<String, DecisionQuestion> questions;

  /// Creates a [CreateDecisionRequest].
  ///
  /// Each entry in [questions] may be a [DecisionQuestion] or a raw
  /// `Map<String, dynamic>` matching the JSON schema.
  CreateDecisionRequest({
    required this.model,
    required this.input,
    required Map<String, Object> questions,
  }) : questions = questions.map((key, value) {
         if (value is DecisionQuestion) {
           return MapEntry(key, value);
         }
         if (value is Map<String, dynamic>) {
           return MapEntry(key, DecisionQuestion.fromJson(value));
         }
         throw ArgumentError.value(
           value,
           'questions[$key]',
           'Must be a DecisionQuestion or Map<String, dynamic>.',
         );
       });

  /// Creates a [CreateDecisionRequest] from a JSON map.
  factory CreateDecisionRequest.fromJson(Map<String, dynamic> json) =>
      CreateDecisionRequest(
        model: json['model'] as String,
        input: json['input'] as Object,
        questions: (json['questions'] as Map<String, dynamic>).cast<
          String,
          Object
        >(),
      );

  /// Serializes this [CreateDecisionRequest] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'model': model,
    'input': input,
    'questions': questions.map((k, q) => MapEntry(k, q.toJson())),
  };
}

/// Response returned from `DecisionsService.create`.
class CreateDecisionResponse {
  /// Calibrated decision answers keyed by question identifiers from [CreateDecisionRequest.questions].
  final Map<String, DecisionAnswer>? answers;

  /// Optional feedback from input content filters if the prompt was blocked.
  final DecisionPromptFeedback? promptFeedback;

  /// Optional token usage statistics for the decision evaluation request.
  final Map<String, dynamic>? usage;

  /// Creates a [CreateDecisionResponse].
  const CreateDecisionResponse({this.answers, this.promptFeedback, this.usage});

  /// Creates a [CreateDecisionResponse] from a JSON map.
  factory CreateDecisionResponse.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>?;
    final rawFeedback =
        (json['prompt_feedback'] ?? json['promptFeedback'])
            as Map<String, dynamic>?;
    return CreateDecisionResponse(
      answers: rawAnswers?.map(
        (k, v) =>
            MapEntry(k, DecisionAnswer.fromJson(v as Map<String, dynamic>)),
      ),
      promptFeedback: rawFeedback == null
          ? null
          : DecisionPromptFeedback.fromJson(rawFeedback),
      usage: json['usage'] as Map<String, dynamic>?,
    );
  }

  /// Serializes this [CreateDecisionResponse] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (answers != null)
      'answers': answers!.map((k, v) => MapEntry(k, v.toJson())),
    if (promptFeedback != null) 'prompt_feedback': promptFeedback!.toJson(),
    if (usage != null) 'usage': usage,
  };
}
