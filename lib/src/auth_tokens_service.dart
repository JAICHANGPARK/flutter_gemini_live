import 'client/api_client.dart';
import 'model/models.dart';

/// Service for generating ephemeral authentication tokens for Gemini Live API connections.
///
/// Ephemeral tokens allow secure, short-lived client-side connections to the
/// Live constrained API without exposing master API keys.
///
/// Supported in `v1alpha` only.
class AuthTokensService {
  final ApiClient _apiClient;

  AuthTokensService(this._apiClient);

  /// Creates an ephemeral authentication token with optional constraints and field locks.
  Future<AuthToken> create(CreateAuthTokenConfig config) async {
    final body = <String, dynamic>{};

    if (config.expireTime != null) {
      body['expireTime'] = config.expireTime;
    }
    if (config.newSessionExpireTime != null) {
      body['newSessionExpireTime'] = config.newSessionExpireTime;
    }
    if (config.uses != null) {
      body['uses'] = config.uses;
    }

    final constraints = config.liveConnectConstraints;
    Map<String, dynamic>? bidiSetup;
    if (constraints != null) {
      final liveConfig = constraints.config is LiveConnectConfig
          ? constraints.config as LiveConnectConfig
          : null;
      bidiSetup = <String, dynamic>{};
      if (constraints.model != null) {
        final model = constraints.model!.startsWith('models/')
            ? constraints.model!
            : 'models/${constraints.model!}';
        bidiSetup['model'] = model;
      }
      final effectiveTranslation =
          constraints.translationConfig ?? liveConfig?.translationConfig;
      if (constraints.config != null || effectiveTranslation != null) {
        final genConfigJson = constraints.config != null
            ? <String, dynamic>{
                if (liveConfig?.generationConfig != null)
                  ...liveConfig!.generationConfig!.toJson(),
                ...superGenerationJson(constraints.config!),
              }
            : <String, dynamic>{};
        if (effectiveTranslation != null &&
            genConfigJson['translation_config'] == null &&
            genConfigJson['translationConfig'] == null) {
          genConfigJson['translationConfig'] = effectiveTranslation.toJson();
        }
        if (genConfigJson.isNotEmpty) {
          bidiSetup['generationConfig'] = genConfigJson;
        }
      }
      final effectiveSystemInstruction =
          constraints.systemInstruction ?? liveConfig?.systemInstruction;
      if (effectiveSystemInstruction != null) {
        bidiSetup['systemInstruction'] = effectiveSystemInstruction.toJson();
      }
      final effectiveTools = constraints.tools ?? liveConfig?.tools;
      if (effectiveTools != null) {
        bidiSetup['tools'] = effectiveTools.map((t) => t.toJson()).toList();
      }
      final effectiveRealtimeInput =
          constraints.realtimeInputConfig ?? liveConfig?.realtimeInputConfig;
      if (effectiveRealtimeInput != null) {
        bidiSetup['realtimeInputConfig'] = effectiveRealtimeInput.toJson();
      }
      final effectiveSessionResumption =
          constraints.sessionResumption ?? liveConfig?.sessionResumption;
      if (effectiveSessionResumption != null) {
        bidiSetup['sessionResumption'] = effectiveSessionResumption.toJson();
      }
      final effectiveCompression =
          constraints.contextWindowCompression ??
          liveConfig?.contextWindowCompression;
      if (effectiveCompression != null) {
        bidiSetup['contextWindowCompression'] = effectiveCompression.toJson();
      }
      final effectiveInputTrans =
          constraints.inputAudioTranscription ??
          liveConfig?.inputAudioTranscription;
      if (effectiveInputTrans != null) {
        bidiSetup['inputAudioTranscription'] = effectiveInputTrans.toJson();
      }
      final effectiveOutputTrans =
          constraints.outputAudioTranscription ??
          liveConfig?.outputAudioTranscription;
      if (effectiveOutputTrans != null) {
        bidiSetup['outputAudioTranscription'] = effectiveOutputTrans.toJson();
      }
      final effectiveProactivity =
          constraints.proactivity ?? liveConfig?.proactivity;
      if (effectiveProactivity != null) {
        bidiSetup['proactivity'] = effectiveProactivity.toJson();
      }
      final effectiveAvatar =
          constraints.avatarConfig ?? liveConfig?.avatarConfig;
      if (effectiveAvatar != null) {
        bidiSetup['avatarConfig'] = effectiveAvatar.toJson();
      }
      final effectiveSafety =
          constraints.safetySettings ?? liveConfig?.safetySettings;
      if (effectiveSafety != null) {
        bidiSetup['safetySettings'] =
            effectiveSafety.map((s) => s.toJson()).toList();
      }
      final effectiveHistory =
          constraints.historyConfig ?? liveConfig?.historyConfig;
      if (effectiveHistory != null) {
        bidiSetup['historyConfig'] = effectiveHistory.toJson();
      }
      final effectiveLabels =
          constraints.labels ??
          constraints.config?.labels ??
          liveConfig?.generationConfig?.labels;
      if (effectiveLabels != null) {
        bidiSetup['labels'] = effectiveLabels;
      }
      body['bidiGenerateContentSetup'] = bidiSetup;
    }

    // Mask generation
    if (config.lockAdditionalFields != null) {
      final fields = <String>[];
      if (bidiSetup != null) {
        for (final entry in bidiSetup.entries) {
          if (entry.value is Map && (entry.value as Map).isNotEmpty) {
            for (final subKey in (entry.value as Map).keys) {
              fields.add('${entry.key}.$subKey');
            }
          } else {
            fields.add(entry.key);
          }
        }
      }
      for (final field in config.lockAdditionalFields!) {
        const genConfigFields = [
          'temperature',
          'topK',
          'topP',
          'maxOutputTokens',
          'responseModalities',
          'seed',
          'speechConfig',
        ];
        if (genConfigFields.contains(field)) {
          fields.add('generationConfig.$field');
        } else {
          fields.add(field);
        }
      }
      if (fields.isNotEmpty) {
        body['fieldMask'] = fields.join(',');
      }
    }

    final response = await _apiClient.post(
      'authTokens',
      body,
      apiVersion: 'v1alpha',
      httpOptions: config.httpOptions,
    );

    return AuthToken.fromJson(response);
  }

  static Map<String, dynamic> superGenerationJson(GenerationConfig config) {
    return GenerationConfig(
      temperature: config.temperature,
      topK: config.topK,
      topP: config.topP,
      maxOutputTokens: config.maxOutputTokens,
      responseModalities: config.responseModalities,
      mediaResolution: config.mediaResolution,
      seed: config.seed,
      speechConfig: config.speechConfig,
      thinkingConfig: config.thinkingConfig,
      enableAffectiveDialog: config.enableAffectiveDialog,
      translationConfig: config.translationConfig,
      audioTranscriptionConfig: config.audioTranscriptionConfig,
    ).toJson();
  }
}
