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
      bidiSetup = <String, dynamic>{};
      if (constraints.model != null) {
        final model = constraints.model!.startsWith('models/')
            ? constraints.model!
            : 'models/${constraints.model!}';
        bidiSetup['model'] = model;
      }
      if (constraints.config != null || constraints.translationConfig != null) {
        final genConfigJson = constraints.config != null
            ? Map<String, dynamic>.from(constraints.config!.toJson())
            : <String, dynamic>{};
        if (constraints.translationConfig != null &&
            genConfigJson['translation_config'] == null &&
            genConfigJson['translationConfig'] == null) {
          genConfigJson['translationConfig'] =
              constraints.translationConfig!.toJson();
        }
        bidiSetup['generationConfig'] = genConfigJson;
      }
      if (constraints.systemInstruction != null) {
        bidiSetup['systemInstruction'] =
            constraints.systemInstruction!.toJson();
      }
      if (constraints.tools != null) {
        bidiSetup['tools'] =
            constraints.tools!.map((t) => t.toJson()).toList();
      }
      if (constraints.realtimeInputConfig != null) {
        bidiSetup['realtimeInputConfig'] =
            constraints.realtimeInputConfig!.toJson();
      }
      if (constraints.sessionResumption != null) {
        bidiSetup['sessionResumption'] =
            constraints.sessionResumption!.toJson();
      }
      if (constraints.contextWindowCompression != null) {
        bidiSetup['contextWindowCompression'] =
            constraints.contextWindowCompression!.toJson();
      }
      if (constraints.inputAudioTranscription != null) {
        bidiSetup['inputAudioTranscription'] =
            constraints.inputAudioTranscription!.toJson();
      }
      if (constraints.outputAudioTranscription != null) {
        bidiSetup['outputAudioTranscription'] =
            constraints.outputAudioTranscription!.toJson();
      }
      if (constraints.proactivity != null) {
        bidiSetup['proactivity'] = constraints.proactivity!.toJson();
      }
      if (constraints.avatarConfig != null) {
        bidiSetup['avatarConfig'] = constraints.avatarConfig!.toJson();
      }
      if (constraints.safetySettings != null) {
        bidiSetup['safetySettings'] =
            constraints.safetySettings!.map((s) => s.toJson()).toList();
      }
      if (constraints.historyConfig != null) {
        bidiSetup['historyConfig'] = constraints.historyConfig!.toJson();
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
    );

    return AuthToken.fromJson(response);
  }
}
