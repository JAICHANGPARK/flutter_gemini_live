// Conversions between the firebase_ai-shaped compat types and the gemini_live
// core models. The core engine stays untouched; only this file knows both.

import 'dart:convert';

import '../../google_genai.dart' as core;
import 'content.dart';
import 'live_api.dart';
import 'tool.dart';

// ============================================================================
// Compat -> core (outgoing)
// ============================================================================

core.Content toCoreContent(Content content) => core.Content(
      role: content.role,
      parts: content.parts.map(toCorePart).toList(),
    );

core.Part toCorePart(Part part) {
  final thought = part.isThought;
  final signature = thoughtSignatureOf(part);
  return switch (part) {
    TextPart(:final text) => core.Part(
        text: text,
        thought: thought,
        thoughtSignature: signature,
      ),
    InlineDataPart() => core.Part(
        inlineData: toCoreBlob(part),
        thought: thought,
        thoughtSignature: signature,
      ),
    FunctionCall(:final name, :final args, :final id) => core.Part(
        functionCall: core.FunctionCall(id: id, name: name, args: args),
        thought: thought,
        thoughtSignature: signature,
      ),
    FunctionResponse() => core.Part(
        functionResponse: toCoreFunctionResponse(part),
        thought: thought,
        thoughtSignature: signature,
      ),
    FileData(:final mimeType, :final fileUri) => core.Part(
        fileData: core.FileData(fileUri: fileUri, mimeType: mimeType),
        thought: thought,
        thoughtSignature: signature,
      ),
    ExecutableCodePart(:final language, :final code) => core.Part(
        executableCode:
            core.ExecutableCode(language: language.toJson(), code: code),
        thought: thought,
        thoughtSignature: signature,
      ),
    CodeExecutionResultPart(:final outcome, :final output) => core.Part(
        codeExecutionResult:
            core.CodeExecutionResult(outcome: outcome.toJson(), output: output),
        thought: thought,
        thoughtSignature: signature,
      ),
    UnknownPart() =>
      core.Part.fromJson(Map<String, dynamic>.from(part.toJson() as Map)),
  };
}

core.Blob toCoreBlob(InlineDataPart part) =>
    core.Blob(mimeType: part.mimeType, data: base64Encode(part.bytes));

core.FunctionResponse toCoreFunctionResponse(FunctionResponse response) =>
    core.FunctionResponse(
      id: response.id,
      name: response.name,
      response: response.response,
    );

core.Tool toCoreTool(Tool tool) {
  final json = tool.toJson();
  final declarations = json['functionDeclarations'] as List?;
  return core.Tool(
    functionDeclarations: declarations
        ?.cast<Map<String, Object?>>()
        .map((d) => core.FunctionDeclaration(
              name: d['name'] as String?,
              description: d['description'] as String?,
              parameters: d['parameters'] as Map<String, dynamic>?,
              parametersJsonSchema: d['parametersJsonSchema'],
            ))
        .toList(),
    googleSearch: json.containsKey('googleSearch') ? core.GoogleSearch() : null,
    codeExecution: json.containsKey('codeExecution') ? const {} : null,
    urlContext: json.containsKey('urlContext') ? const {} : null,
    googleMaps: json.containsKey('googleMaps') ? core.GoogleMaps() : null,
  );
}

core.Modality toCoreModality(ResponseModalities modality) =>
    switch (modality) {
      ResponseModalities.text => core.Modality.TEXT,
      ResponseModalities.image => core.Modality.IMAGE,
      ResponseModalities.audio => core.Modality.AUDIO,
    };

core.MediaResolution? toCoreMediaResolution(MediaResolution? resolution) =>
    switch (resolution) {
      null => null,
      MediaResolution.low => core.MediaResolution.MEDIA_RESOLUTION_LOW,
      MediaResolution.medium => core.MediaResolution.MEDIA_RESOLUTION_MEDIUM,
      MediaResolution.high => core.MediaResolution.MEDIA_RESOLUTION_HIGH,
      MediaResolution.unspecified ||
      MediaResolution.ultraHigh =>
        core.MediaResolution.MEDIA_RESOLUTION_UNSPECIFIED,
    };

core.VoiceConfig _prebuiltVoice(String voiceName) => core.VoiceConfig(
      prebuiltVoiceConfig: core.PrebuiltVoiceConfig(voiceName: voiceName),
    );

core.SpeechConfig toCoreSpeechConfig(SpeechConfig config) => core.SpeechConfig(
      voiceConfig:
          config.voiceName == null ? null : _prebuiltVoice(config.voiceName!),
      languageCode: config.languageCode,
      multiSpeakerVoiceConfig: config.multiSpeakerVoiceConfig == null
          ? null
          : core.MultiSpeakerVoiceConfig(
              speakerVoiceConfigs: config
                  .multiSpeakerVoiceConfig!.speakerVoiceConfigs
                  .map((s) => core.SpeakerVoiceConfig(
                        speaker: s.speaker,
                        voiceConfig: _prebuiltVoice(s.voiceName),
                      ))
                  .toList(),
            ),
    );

core.GenerationConfig toCoreGenerationConfig(LiveGenerationConfig config) =>
    core.GenerationConfig(
      temperature: config.temperature,
      topK: config.topK,
      topP: config.topP,
      maxOutputTokens: config.maxOutputTokens,
      responseModalities:
          config.responseModalities?.map(toCoreModality).toList(),
      mediaResolution: toCoreMediaResolution(config.mediaResolution),
      speechConfig: config.speechConfig == null
          ? null
          : toCoreSpeechConfig(config.speechConfig!),
    );

core.AudioTranscriptionConfig? toCoreTranscription(
        AudioTranscriptionConfig? config) =>
    config == null ? null : core.AudioTranscriptionConfig();

core.ContextWindowCompressionConfig? toCoreContextWindowCompression(
        ContextWindowCompressionConfig? config) =>
    config == null
        ? null
        : core.ContextWindowCompressionConfig(
            triggerTokens: config.triggerTokens?.toString(),
            slidingWindow: config.slidingWindow == null
                ? null
                : core.SlidingWindow(
                    targetTokens:
                        config.slidingWindow!.targetTokens?.toString(),
                  ),
          );

core.RealtimeInputConfig? toCoreRealtimeInputConfig(
    RealtimeInputConfig? config) {
  if (config == null) return null;
  final detection = config.automaticActivityDetection;
  return core.RealtimeInputConfig(
    automaticActivityDetection: detection == null
        ? null
        : core.AutomaticActivityDetection(
            disabled: detection.disabled,
            startOfSpeechSensitivity: switch (detection.startSensitivity) {
              null => null,
              Sensitivity.low => core.StartSensitivity.START_SENSITIVITY_LOW,
              Sensitivity.high => core.StartSensitivity.START_SENSITIVITY_HIGH,
            },
            endOfSpeechSensitivity: switch (detection.endSensitivity) {
              null => null,
              Sensitivity.low => core.EndSensitivity.END_SENSITIVITY_LOW,
              Sensitivity.high => core.EndSensitivity.END_SENSITIVITY_HIGH,
            },
            prefixPaddingMs: detection.prefixPaddingMS,
            silenceDurationMs: detection.silenceDurationMS,
          ),
    activityHandling: switch (config.activityHandling) {
      null => null,
      ActivityHandling.interrupt =>
        core.ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
      ActivityHandling.noInterrupt => core.ActivityHandling.NO_INTERRUPTION,
    },
    turnCoverage: switch (config.turnCoverage) {
      null => null,
      TurnCoverage.onlyActivity =>
        core.TurnCoverage.TURN_INCLUDES_ONLY_ACTIVITY,
      TurnCoverage.allInput => core.TurnCoverage.TURN_INCLUDES_ALL_INPUT,
      TurnCoverage.audioActivityAndAllVideo =>
        core.TurnCoverage.TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO,
    },
  );
}

core.SessionResumptionConfig? toCoreSessionResumption(
        SessionResumptionConfig? config) =>
    config == null ? null : core.SessionResumptionConfig(handle: config.handle);

// ============================================================================
// Core -> compat (incoming)
// ============================================================================

/// Converts one core server message into the firebase_ai message types.
///
/// A single core message can carry several payloads (for example content and
/// usage metadata). Each Firebase-visible payload becomes its own message, in
/// the order firebase_ai checks them. Payloads firebase_ai has no type for
/// (usage metadata, voice activity) produce nothing here.
List<LiveServerMessage> fromCoreServerMessage(core.LiveServerMessage msg) => [
      if (msg.serverContent case final content?) _fromCoreContent(content),
      if (msg.toolCall case final toolCall?)
        LiveServerToolCall(
          functionCalls: [
            for (final call in toolCall.functionCalls ?? <core.FunctionCall>[])
              functionCallFromServer(
                call.name ?? '',
                call.args ?? const {},
                id: call.id,
              ),
          ],
        ),
      if (msg.toolCallCancellation case final cancellation?)
        LiveServerToolCallCancellation(functionIds: cancellation.ids),
      if (msg.setupComplete != null) LiveServerSetupComplete(),
      if (msg.goAway case final goAway?)
        GoingAwayNotice(timeLeft: goAway.timeLeft),
      if (msg.sessionResumptionUpdate case final update?)
        SessionResumptionUpdate(
          newHandle: update.newHandle,
          resumable: update.resumable,
          lastConsumedClientMessageIndex:
              int.tryParse(update.lastConsumedClientMessageIndex ?? ''),
        ),
    ];

LiveServerContent _fromCoreContent(core.LiveServerContent content) =>
    LiveServerContent(
      modelTurn: content.modelTurn == null
          ? null
          : fromCoreContent(content.modelTurn!),
      turnComplete: content.turnComplete,
      interrupted: content.interrupted,
      inputTranscription: _fromCoreTranscription(content.inputTranscription),
      outputTranscription: _fromCoreTranscription(content.outputTranscription),
    );

Transcription? _fromCoreTranscription(core.Transcription? t) =>
    t == null ? null : Transcription(text: t.text, finished: t.finished);

Content fromCoreContent(core.Content content) => Content(
      content.role,
      (content.parts ?? const <core.Part>[]).map(fromCorePart).toList(),
    );

Part fromCorePart(core.Part part) {
  final thought = part.thought;
  final signature = part.thoughtSignature;
  if (part.text case final text?) {
    return textPartFromServer(text,
        isThought: thought, thoughtSignature: signature);
  }
  if (part.inlineData case final blob?) {
    return inlineDataPartFromServer(blob.mimeType, base64Decode(blob.data),
        isThought: thought, thoughtSignature: signature);
  }
  if (part.functionCall case final call?) {
    return functionCallFromServer(call.name ?? '', call.args ?? const {},
        id: call.id, isThought: thought, thoughtSignature: signature);
  }
  if (part.functionResponse case final response?) {
    return FunctionResponse(response.name ?? '', response.response ?? const {},
        id: response.id, isThought: thought);
  }
  if (part.fileData case final file?) {
    return FileData(file.mimeType ?? '', file.fileUri ?? '',
        isThought: thought);
  }
  if (part.executableCode case final code?) {
    return ExecutableCodePart(
      language: CodeLanguage.parseValue(code.language ?? ''),
      code: code.code ?? '',
      isThought: thought,
    );
  }
  if (part.codeExecutionResult case final result?) {
    return CodeExecutionResultPart(
      outcome: Outcome.parseValue(result.outcome ?? ''),
      output: result.output ?? '',
      isThought: thought,
    );
  }
  return UnknownPart(part.toJson());
}
