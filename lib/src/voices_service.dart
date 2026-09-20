import 'package:http/http.dart' as http;

import 'client/api_client.dart';
import 'model/models.dart';

/// Service for managing custom voices and listing system voice catalog resources
/// using the Gemini Voices API.
///
/// Use this service to:
/// - List stored custom voices and prebuilt Google catalog voices.
/// - Create custom voices from natural-language prompts (`prompted`) or audio recordings (`replicated`).
/// - Retrieve custom voice metadata by ID.
/// - Delete custom voices by ID.
class GeminiVoicesService {
  final ApiClient _apiClient;

  /// Creates a new [GeminiVoicesService].
  GeminiVoicesService({
    required String apiKey,
    String? baseUrl,
    String apiVersion = 'v1alpha',
    http.Client? httpClient,
  }) : _apiClient = ApiClient(
          apiKey: apiKey,
          baseUrl: baseUrl,
          apiVersion: apiVersion,
          httpClient: httpClient,
        );

  /// Internal constructor with pre-configured [ApiClient].
  GeminiVoicesService.fromApiClient(this._apiClient);

  /// Lists custom stored voices owned by the caller followed by prebuilt
  /// system voices from Google's voice catalog.
  Future<ListVoicesResponse> listVoices({
    int? pageSize,
    String? pageToken,
    String? search,
    VoiceType? type,
    String? gender,
    VoicePitch? pitch,
    String? languageCode,
    String? accent,
    String? persona,
    String? context,
    String? regionCode,
  }) async {
    final queryParams = <String, String>{};
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();
    if (pageToken != null) queryParams['pageToken'] = pageToken;
    if (search != null) queryParams['search'] = search;
    if (type != null) {
      queryParams['type'] = switch (type) {
        VoiceType.replicated => 'replicated',
        VoiceType.prompted => 'prompted',
        VoiceType.prebuilt => 'prebuilt',
      };
    }
    if (gender != null) queryParams['gender'] = gender;
    if (pitch != null) {
      queryParams['pitch'] = switch (pitch) {
        VoicePitch.low => 'low',
        VoicePitch.medium => 'medium',
        VoicePitch.high => 'high',
      };
    }
    if (languageCode != null) queryParams['languageCode'] = languageCode;
    if (accent != null) queryParams['accent'] = accent;
    if (persona != null) queryParams['persona'] = persona;
    if (context != null) queryParams['context'] = context;
    if (regionCode != null) queryParams['regionCode'] = regionCode;

    final json = await _apiClient.get(
      'voices',
      queryParams.isEmpty ? null : queryParams,
    );
    return ListVoicesResponse.fromJson(json);
  }

  /// Creates a custom voice from a natural-language prompt (`prompted`)
  /// or from reference and consent audio recordings (`replicated`).
  Future<VoiceResource> createVoice(CreateVoiceRequest request) async {
    final json = await _apiClient.post('voices', request.toJson());
    return VoiceResource.fromJson(json);
  }

  /// Gets a custom stored voice by resource ID (e.g. `voice_abc123`).
  Future<VoiceResource> getVoice(String id) async {
    final cleanId = id.startsWith('voices/') ? id.substring(7) : id;
    final json = await _apiClient.get('voices/$cleanId');
    return VoiceResource.fromJson(json);
  }

  /// Deletes a custom stored voice by resource ID (e.g. `voice_abc123`).
  Future<DeleteVoiceResponse> deleteVoice(String id) async {
    final cleanId = id.startsWith('voices/') ? id.substring(7) : id;
    final json = await _apiClient.delete('voices/$cleanId');
    return DeleteVoiceResponse.fromJson(json);
  }

  /// Closes the underlying HTTP client.
  void close() {
    _apiClient.close();
  }
}
