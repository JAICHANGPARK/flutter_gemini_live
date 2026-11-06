// lib/src/api_client.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/models.dart';
import '../platform/runtime_info_stub.dart'
    if (dart.library.io) '../platform/runtime_info_io.dart'
    if (dart.library.html) '../platform/runtime_info_web.dart'
    as runtime_info;

/// A low-level client responsible for making authenticated HTTP requests to the
/// Google Generative AI API backend.
///
/// This class handles the construction of request URIs, adding the API key or
/// per-request bearer credentials, populating `X-Server-Timeout`, and processing
/// HTTP responses without leaking per-request headers into client defaults.
class ApiClient {
  static const _sdkVersion = '3.0.0';

  /// Default API version for the Gemini Developer API.
  static const googleAiApiDefaultVersion = 'v1beta';

  static String? _defaultGoogleAiApiVersionOverride;

  /// Overrides the default API version for the Gemini Developer API when no
  /// explicit version is configured.
  static void setDefaultGoogleAiApiVersion([String? version]) {
    _defaultGoogleAiApiVersionOverride = version;
  }

  /// Resolves the effective default API version from the
  /// `GOOGLE_GENAI_API_VERSION` environment variable, any override configured
  /// via [setDefaultGoogleAiApiVersion], or [fallback].
  ///
  /// When `GOOGLE_GENAI_API_VERSION` is `'beta'`, resolves to `'v1beta'`. Any
  /// other non-empty value is returned verbatim.
  static String resolveDefaultApiVersion({
    String fallback = googleAiApiDefaultVersion,
    Map<String, String>? environmentOverride,
  }) {
    final rawEnv = environmentOverride != null
        ? environmentOverride['GOOGLE_GENAI_API_VERSION']
        : runtime_info.getEnvironmentVariable('GOOGLE_GENAI_API_VERSION');
    final envVersion = rawEnv?.trim();
    if (envVersion != null && envVersion.isNotEmpty) {
      return envVersion == 'beta' ? 'v1beta' : envVersion;
    }
    return _defaultGoogleAiApiVersionOverride ?? fallback;
  }

  /// Substitutes `{api_version}` in a request [path] template.
  ///
  /// For example, `'upload/{api_version}/files'` becomes
  /// `'upload/v1beta/files'`. If [apiVersion] is empty or `null`, the
  /// `{api_version}` segment is omitted without leaving a double slash
  /// (e.g., `'upload/files'`).
  static String resolveApiVersionInPath(String path, String? apiVersion) {
    const placeholder = '{api_version}';
    if (apiVersion != null && apiVersion.isNotEmpty) {
      return path.replaceAll(placeholder, apiVersion);
    }
    return path
        .replaceAll('$placeholder/', '')
        .replaceAll('/$placeholder', '')
        .replaceAll(placeholder, '');
  }

  /// The API key for authenticating with the Google AI services.
  final String apiKey;

  /// The base URL for the API endpoint.
  ///
  /// If not provided, a default production URL is used. This can be overridden
  /// for testing or to connect to a different environment.
  final String? baseUrl;

  /// The version of the API to target, e.g., `'v1beta'`.
  final String apiVersion;

  /// Optional default HTTP headers applied to every request.
  ///
  /// Stored as an unmodifiable copy so per-request headers (`Authorization`,
  /// `X-Server-Timeout`, `x-goog-user-project`, etc.) never leak into client defaults.
  final Map<String, String>? headers;

  /// Client-level [HttpOptions] configuration.
  final HttpOptions httpOptions;

  /// Optional bearer token and quota project credentials resolved per request.
  final GenAICredentials? credentials;

  /// The underlying HTTP client for making network requests.
  final http.Client _httpClient;

  /// Creates an instance of [ApiClient].
  ApiClient({
    required this.apiKey,
    String? baseUrl,
    String? apiVersion,
    Map<String, String>? headers,
    HttpOptions? httpOptions,
    this.credentials,
    http.Client? httpClient,
  }) : baseUrl = baseUrl ?? httpOptions?.baseUrl,
       apiVersion =
           httpOptions?.apiVersion ?? apiVersion ?? resolveDefaultApiVersion(),
       headers = (headers != null || httpOptions?.headers != null)
           ? Map<String, String>.unmodifiable(<String, String>{
               ...?httpOptions?.headers,
               ...?headers,
             })
           : null,
       httpOptions = HttpOptions(
         baseUrl: baseUrl ?? httpOptions?.baseUrl,
         apiVersion:
             httpOptions?.apiVersion ??
             apiVersion ??
             resolveDefaultApiVersion(),
         headers: Map<String, String>.unmodifiable(<String, String>{
           ...?httpOptions?.headers,
           ...?headers,
         }),
         timeout: httpOptions?.timeout,
         extraBody: httpOptions?.extraBody,
         retryOptions: httpOptions?.retryOptions,
         clientArgs: httpOptions?.clientArgs,
         asyncClientArgs: httpOptions?.asyncClientArgs,
       ),
       _httpClient = httpClient ?? http.Client();

  /// Populates the `X-Server-Timeout` header (in whole seconds, rounded up)
  /// from [timeoutMs] (in milliseconds) if not already present in [targetHeaders].
  static void populateServerTimeoutHeader(
    Map<String, String> targetHeaders,
    int? timeoutMs,
  ) {
    if (timeoutMs != null &&
        timeoutMs > 0 &&
        !targetHeaders.containsKey('X-Server-Timeout')) {
      final timeoutSeconds = (timeoutMs / 1000.0).ceil();
      targetHeaders['X-Server-Timeout'] = timeoutSeconds.toString();
    }
  }

  /// Constructs the full request [Uri] for a given API [path].
  Uri _buildUri(
    String path, [
    Map<String, String>? queryParams,
    String? customApiVersion,
    HttpOptions? requestHttpOptions,
  ]) {
    if (apiKey.startsWith('auth_tokens/')) {
      throw ArgumentError('Ephemeral tokens can only be used with the live API.');
    }
    final patched = httpOptions.merge(requestHttpOptions);
    final rawBaseUrl =
        patched.baseUrl ??
        baseUrl ??
        'https://generativelanguage.googleapis.com';
    final effectiveBaseUrl = rawBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final effectiveApiVersion =
        requestHttpOptions?.apiVersion ??
        customApiVersion ??
        patched.apiVersion ??
        apiVersion;
    final Uri baseUri;
    if (path.contains('{api_version}')) {
      final resolvedPath = resolveApiVersionInPath(path, effectiveApiVersion);
      baseUri = Uri.parse(
        resolvedPath.isEmpty
            ? effectiveBaseUrl
            : '$effectiveBaseUrl/$resolvedPath',
      );
    } else if (effectiveApiVersion.isEmpty) {
      baseUri = Uri.parse('$effectiveBaseUrl/$path');
    } else {
      baseUri = Uri.parse('$effectiveBaseUrl/$effectiveApiVersion/$path');
    }
    final query = Map<String, String>.from(baseUri.queryParameters);
    if (apiKey.isNotEmpty) {
      query['key'] = apiKey;
    }
    if (queryParams != null) {
      query.addAll(queryParams);
    }
    return baseUri.replace(queryParameters: query);
  }

  /// Builds a fresh per-request headers map from [defaultHeaders] and [requestHttpOptions].
  ///
  /// Includes the default `User-Agent` and `x-goog-api-client` SDK headers
  /// while preserving any caller-supplied overrides in [headers] or
  /// [requestHttpOptions], without mutating [headers] or [httpOptions].
  Future<Map<String, String>> buildRequestHeaders(
    Map<String, String> defaultHeaders, [
    HttpOptions? requestHttpOptions,
  ]) async {
    final patched = httpOptions.merge(requestHttpOptions);
    final sdkHeader =
        'google-genai-sdk/$_sdkVersion dart/${runtime_info.dartVersion()}';
    // Copy so per-request headers do not become client defaults.
    final reqHeaders = <String, String>{
      'User-Agent': sdkHeader,
      'x-goog-api-client': sdkHeader,
      ...defaultHeaders,
    };
    if (patched.headers != null) {
      for (final entry in patched.headers!.entries) {
        if (entry.key.toLowerCase() == 'user-agent') {
          reqHeaders.remove('User-Agent');
          reqHeaders.remove('user-agent');
        } else if (entry.key.toLowerCase() == 'x-goog-api-client') {
          reqHeaders.remove('x-goog-api-client');
        }
        reqHeaders[entry.key] = entry.value;
      }
    }

    populateServerTimeoutHeader(reqHeaders, patched.timeout);

    if (credentials != null) {
      final token = await credentials!.resolveToken();
      if (token != null &&
          token.isNotEmpty &&
          !reqHeaders.containsKey('Authorization')) {
        reqHeaders['Authorization'] = 'Bearer $token';
      }
      final quotaProject = credentials!.quotaProjectId;
      if (quotaProject != null &&
          quotaProject.isNotEmpty &&
          !reqHeaders.containsKey('x-goog-user-project')) {
        reqHeaders['x-goog-user-project'] = quotaProject;
      }
    }

    return reqHeaders;
  }

  /// Sends a GET request to the specified API [path].
  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, String>? queryParams,
    String? apiVersion,
    HttpOptions? httpOptions,
  ]) async {
    final uri = _buildUri(path, queryParams, apiVersion, httpOptions);
    final reqHeaders = await buildRequestHeaders(
      const {'Accept': 'application/json'},
      httpOptions,
    );
    final response = await _httpClient.get(uri, headers: reqHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Sends a POST request to the specified API [path] with a JSON [body].
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? apiVersion,
    HttpOptions? httpOptions,
  }) async {
    final uri = _buildUri(path, null, apiVersion, httpOptions);
    final patched = this.httpOptions.merge(httpOptions);
    final effectiveBody = patched.extraBody != null
        ? <String, dynamic>{...body, ...patched.extraBody!}
        : body;
    final reqHeaders = await buildRequestHeaders(
      const {'Content-Type': 'application/json'},
      httpOptions,
    );
    final response = await _httpClient.post(
      uri,
      headers: reqHeaders,
      body: jsonEncode(effectiveBody),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Sends a DELETE request to the specified API [path].
  Future<Map<String, dynamic>> delete(
    String path, {
    String? apiVersion,
    HttpOptions? httpOptions,
  }) async {
    final uri = _buildUri(path, null, apiVersion, httpOptions);
    final reqHeaders = await buildRequestHeaders(
      const {'Accept': 'application/json'},
      httpOptions,
    );
    final response = await _httpClient.delete(uri, headers: reqHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Closes the underlying HTTP client, releasing associated resources.
  void close() {
    _httpClient.close();
  }
}
