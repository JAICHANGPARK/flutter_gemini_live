// lib/src/api_client.dart

import 'dart:convert'; // Required for JSON encoding and decoding.

import 'package:http/http.dart' as http; // The foundation for making HTTP requests.

/// A low-level client responsible for making authenticated HTTP requests to the
/// Google Generative AI API backend.
///
/// This class handles the construction of request URIs, adding the API key,
/// and processing HTTP responses. It is designed to be an internal utility
/// and is not intended for direct use by end-users of the library.
class ApiClient {
  /// The API key for authenticating with the Google AI services.
  final String apiKey;

  /// The base URL for the API endpoint.
  ///
  /// If not provided, a default production URL is used. This can be overridden
  /// for testing or to connect to a different environment.
  final String? baseUrl;

  /// The version of the API to target, e.g., 'v1beta'.
  final String apiVersion;

  /// The underlying HTTP client for making network requests.
  ///
  /// This client is either provided via the constructor or created internally.
  /// The [close] method must be called to release its resources.
  final http.Client _httpClient;

  /// Creates an instance of the [ApiClient].
  ///
  /// [apiKey] is required for all requests.
  /// [baseUrl] can be specified to override the default API endpoint.
  /// [apiVersion] defaults to 'v1beta'.
  /// [httpClient] is an optional HTTP client to use for requests. If not
  /// provided, a new `http.Client()` instance is created.
  ApiClient({
    required this.apiKey,
    this.baseUrl,
    this.apiVersion = 'v1beta',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(); // Use provided client or create a new one.

  /// Constructs the full request [Uri] for a given API [path].
  ///
  /// It combines the [baseUrl] (or a default), [apiVersion], the resource [path],
  /// and attaches the [apiKey] as a query parameter for authentication.
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    // Use the provided baseUrl or fall back to the default Google API endpoint.
    final effectiveBaseUrl =
        baseUrl ?? 'https://generativelanguage.googleapis.com';
    final baseUri = Uri.parse('$effectiveBaseUrl/$apiVersion/$path');
    final query = Map<String, String>.from(baseUri.queryParameters);
    query['key'] = apiKey;
    if (queryParams != null) {
      query.addAll(queryParams);
    }
    return baseUri.replace(queryParameters: query);
  }

  /// Sends a GET request to the specified API [path].
  ///
  /// - [path]: The specific API resource path (e.g., 'voices').
  /// - [queryParams]: Optional query parameters to append.
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, String>? queryParams,
  ]) async {
    final uri = _buildUri(path, queryParams);
    final response = await _httpClient.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Sends a POST request to the specified API [path] with a JSON [body].
  ///
  /// This method handles JSON serialization of the request body and
  /// deserialization of the response body.
  ///
  /// - [path]: The specific API resource path (e.g., 'models/gemini-pro:generateContent').
  /// - [body]: The request payload, which will be JSON-encoded.
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>] on success.
  ///
  /// Throws an [Exception] if the API returns a non-successful status code (not 2xx).
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _buildUri(path);
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body), // Serialize the request body to a JSON string.
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If the request was successful, decode the JSON body and return it.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // If the server returned an error, throw an exception with details.
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Sends a DELETE request to the specified API [path].
  ///
  /// - [path]: The specific API resource path (e.g., 'voices/voice_123').
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  Future<Map<String, dynamic>> delete(String path) async {
    final uri = _buildUri(path);
    final response = await _httpClient.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Closes the underlying HTTP client, releasing associated resources.
  ///
  /// This method should be called when the [ApiClient] is no longer needed
  /// to prevent resource leaks. It is safe to call this method multiple times.
  void close() {
    _httpClient.close();
  }
}