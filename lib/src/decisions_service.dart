import 'client/api_client.dart';
import 'model/models.dart';

/// Service for evaluating structured decision questions (`POST /{api_version}/decisions`).
///
/// Mirrors `client.decisions.create` in the upstream `@google/genai` (JS/TS)
/// and `google-genai` (Python) SDKs.
class DecisionsService {
  final ApiClient _apiClient;

  /// Creates a [DecisionsService] backed by the given [ApiClient].
  DecisionsService(this._apiClient);

  /// Evaluates a batch of structured decision questions against a shared input context.
  ///
  /// Sends a `POST /{api_version}/decisions` request using [request]. Optional
  /// [apiVersion] and [httpOptions] override client-level transport settings
  /// for this call.
  Future<CreateDecisionResponse> create(
    CreateDecisionRequest request, {
    String? apiVersion,
    HttpOptions? httpOptions,
  }) async {
    final response = await _apiClient.post(
      'decisions',
      request.toJson(),
      apiVersion: apiVersion,
      httpOptions: httpOptions,
    );
    return CreateDecisionResponse.fromJson(response);
  }
}
