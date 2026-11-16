// lib/src/api_client.dart

import 'dart:convert';
import 'dart:typed_data';

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
  static const _sdkVersion = '3.3.0';

  static final RegExp _charsetPattern = RegExp(
    r';\s*charset\s*=\s*"?([^\s;"]+)"?',
    caseSensitive: false,
  );

  static const Set<String> _truthyDebugFlags = <String>{
    'true',
    '1',
    'yes',
    'on',
  };

  /// Default API version for the Gemini Developer API.
  ///
  /// Defaults to `'v1beta'` so Gemini Live (`BidiGenerateContent`), `-latest`
  /// model aliases (`gemini-flash-latest`, `gemini-flash-lite-latest`,
  /// `gemini-pro-latest`), and `-preview` models work out of the box (several
  /// of these models and endpoints are unavailable on `'v1'`).
  static const googleAiApiDefaultVersion = 'v1beta';

  static String? _defaultGoogleAiApiVersionOverride;

  /// Overrides the default API version for the Gemini Developer API when no
  /// explicit version is configured.
  static void setDefaultGoogleAiApiVersion([String? version]) {
    _defaultGoogleAiApiVersionOverride = version;
  }

  /// Resolves the default API key from the `GEMINI_API_KEY` or
  /// `GOOGLE_API_KEY` environment variables, or returns an empty string when
  /// neither variable is set.
  ///
  /// Precedence gives `GEMINI_API_KEY` priority over `GOOGLE_API_KEY`.
  static String resolveDefaultApiKey({
    Map<String, String>? environmentOverride,
  }) {
    String? readEnv(String name) => environmentOverride != null
        ? environmentOverride[name]
        : runtime_info.getEnvironmentVariable(name);

    final geminiKey = readEnv('GEMINI_API_KEY')?.trim();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      return geminiKey;
    }
    final googleKey = readEnv('GOOGLE_API_KEY')?.trim();
    if (googleKey != null && googleKey.isNotEmpty) {
      return googleKey;
    }
    return '';
  }

  /// Returns whether SDK debug logging is enabled via the `GOOGLE_GENAI_DEBUG`
  /// environment variable.
  ///
  /// Recognizes `'true'`, `'1'`, `'yes'`, and `'on'` (case-insensitive).
  static bool isDebugEnabled({Map<String, String>? environmentOverride}) {
    final raw = environmentOverride != null
        ? environmentOverride['GOOGLE_GENAI_DEBUG']
        : runtime_info.getEnvironmentVariable('GOOGLE_GENAI_DEBUG');
    final normalized = raw?.trim().toLowerCase();
    return normalized != null && _truthyDebugFlags.contains(normalized);
  }

  /// Resolves the text [Encoding] declared in HTTP [headers], defaulting to
  /// [utf8] when `Content-Type` omits an explicit `charset` parameter.
  ///
  /// Unlike `package:http`'s default `ISO-8859-1` (`latin1`) fallback, JSON and
  /// `text/event-stream` responses without an explicit charset are decoded as
  /// UTF-8 while preserving any explicit charset declared by the server.
  static Encoding resolveResponseEncoding(Map<String, String>? headers) {
    if (headers != null) {
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'content-type') {
          final match = _charsetPattern.firstMatch(entry.value);
          final charset = match?.group(1)?.trim();
          if (charset != null && charset.isNotEmpty) {
            final explicit = Encoding.getByName(charset);
            if (explicit != null) {
              return explicit;
            }
          }
          break;
        }
      }
    }
    return utf8;
  }

  /// Decodes an HTTP [response] body using its declared `Content-Type` charset,
  /// or UTF-8 by default when no explicit `charset` parameter is present.
  static String decodeResponseBody(http.Response response) {
    final encoding = resolveResponseEncoding(response.headers);
    if (identical(encoding, utf8)) {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }
    return encoding.decode(response.bodyBytes);
  }

  /// Merges all case variants of [headerKey] in [headers] into a single key
  /// ([targetKey] when provided, otherwise lowercase [headerKey]), preserving
  /// value order and dropping duplicate values.
  static void collapseHeaderCaseVariants(
    Map<String, String> headers,
    String headerKey, {
    String? targetKey,
  }) {
    final lowerKey = headerKey.toLowerCase();
    final variantKeys = headers.keys
        .where((k) => k.toLowerCase() == lowerKey)
        .toList();
    if (variantKeys.isEmpty) {
      return;
    }
    final seenValues = <String>{};
    final orderedValues = <String>[];
    for (final key in variantKeys) {
      final value = headers.remove(key);
      if (value != null && seenValues.add(value)) {
        orderedValues.add(value);
      }
    }
    headers[targetKey ?? lowerKey] = orderedValues.join(' ');
  }

  /// Collapses case variants of `User-Agent` and `x-goog-api-client` in
  /// [headers] and appends the SDK and Dart runtime telemetry labels
  /// idempotently.
  static void appendLibraryVersionHeaders(Map<String, String> headers) {
    collapseHeaderCaseVariants(headers, 'user-agent');
    collapseHeaderCaseVariants(headers, 'x-goog-api-client');
    final libraryLabel = 'google-genai-sdk/$_sdkVersion';
    final languageLabel = 'dart/${runtime_info.dartVersion()}';
    final versionHeaderValue = '$libraryLabel $languageLabel';

    for (final key in const <String>['user-agent', 'x-goog-api-client']) {
      final existing = headers[key];
      if (existing != null && !existing.contains(libraryLabel)) {
        headers[key] =
            existing.isEmpty ? versionHeaderValue : '$versionHeaderValue $existing';
      } else if (existing != null && !existing.contains(languageLabel)) {
        headers[key] = '$existing $languageLabel';
      } else if (existing == null) {
        headers[key] = versionHeaderValue;
      }
    }
  }

  /// Splits an SSE [byteStream] into decoded lines strictly at CR (`\r`), LF
  /// (`\n`), or CRLF (`\r\n`) boundaries.
  ///
  /// Unlike generic Unicode line splitters, characters such as `U+2028`,
  /// `U+2029`, and `U+0085` inside JSON strings are never treated as line
  /// terminators, and a CRLF pair split across chunk boundaries produces a
  /// single line break.
  static Stream<String> splitSseLines(
    Stream<List<int>> byteStream, {
    Encoding encoding = utf8,
  }) async* {
    final lineBuffer = BytesBuilder(copy: false);
    var trailingCr = false;

    String decodeLine(Uint8List bytes) {
      if (identical(encoding, utf8)) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      return encoding.decode(bytes);
    }

    await for (final chunk in byteStream) {
      if (chunk.isEmpty) {
        continue;
      }
      var index = 0;
      if (trailingCr) {
        trailingCr = false;
        if (chunk[0] == 0x0A) {
          index = 1;
        }
        yield decodeLine(lineBuffer.takeBytes());
      }
      var segmentStart = index;
      while (index < chunk.length) {
        final byte = chunk[index];
        if (byte == 0x0D) {
          if (index > segmentStart) {
            lineBuffer.add(chunk.sublist(segmentStart, index));
          }
          if (index + 1 < chunk.length) {
            if (chunk[index + 1] == 0x0A) {
              index += 2;
            } else {
              index += 1;
            }
            yield decodeLine(lineBuffer.takeBytes());
            segmentStart = index;
          } else {
            trailingCr = true;
            index += 1;
            segmentStart = index;
          }
        } else if (byte == 0x0A) {
          if (index > segmentStart) {
            lineBuffer.add(chunk.sublist(segmentStart, index));
          }
          yield decodeLine(lineBuffer.takeBytes());
          index += 1;
          segmentStart = index;
        } else {
          index += 1;
        }
      }
      if (segmentStart < chunk.length) {
        lineBuffer.add(chunk.sublist(segmentStart));
      }
    }

    if (trailingCr || lineBuffer.isNotEmpty) {
      yield decodeLine(lineBuffer.takeBytes());
    }
  }

  /// Decodes a streaming Server-Sent Events (`text/event-stream`) [byteStream]
  /// into parsed JSON event maps using UTF-8 by default unless [headers]
  /// specifies an explicit `charset`.
  ///
  /// Splits lines strictly on CR, LF, and CRLF, reassembles multi-byte UTF-8
  /// sequences across chunk boundaries, supports multi-line `data:` blocks, and
  /// buffers raw multi-line JSON payloads via [RawJsonLineBuffer] while
  /// ignoring braces inside JSON string literals.
  static Stream<Map<String, dynamic>> decodeSseJsonStream(
    Stream<List<int>> byteStream, {
    Map<String, String>? headers,
  }) async* {
    final encoding = resolveResponseEncoding(headers);
    final rawBuffer = RawJsonLineBuffer();
    final dataBuffer = <String>[];

    Map<String, dynamic>? tryDecodeEvent(String rawPayload) {
      final payload = rawPayload.trim();
      if (payload.isEmpty || payload == '[DONE]') {
        return null;
      }
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    }

    await for (final line in splitSseLines(byteStream, encoding: encoding)) {
      if (line.isEmpty) {
        if (dataBuffer.isNotEmpty) {
          final joined = dataBuffer.join('\n');
          dataBuffer.clear();
          final event = tryDecodeEvent(joined);
          if (event != null) {
            yield event;
          }
        }
        continue;
      }
      if (line.startsWith(':')) {
        continue;
      }
      if (line.startsWith('data:')) {
        final content = line.startsWith('data: ')
            ? line.substring(6)
            : line.substring(5);
        dataBuffer.add(content);
        continue;
      }
      if (line.startsWith('event:') ||
          line.startsWith('id:') ||
          line.startsWith('retry:')) {
        continue;
      }
      final completedJson = rawBuffer.addLine(line);
      if (completedJson != null) {
        final event = tryDecodeEvent(completedJson);
        if (event != null) {
          yield event;
        }
      }
    }

    final remainingRaw = rawBuffer.flush();
    if (remainingRaw.isNotEmpty) {
      final event = tryDecodeEvent(remainingRaw);
      if (event != null) {
        yield event;
      }
    }
    if (dataBuffer.isNotEmpty) {
      final event = tryDecodeEvent(dataBuffer.join('\n'));
      if (event != null) {
        yield event;
      }
    }
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
  ///
  /// When [apiKey] is omitted, resolves the key from `GEMINI_API_KEY` or
  /// `GOOGLE_API_KEY` via [resolveDefaultApiKey].
  ApiClient({
    String? apiKey,
    String? baseUrl,
    String? apiVersion,
    Map<String, String>? headers,
    HttpOptions? httpOptions,
    this.credentials,
    http.Client? httpClient,
  }) : apiKey = apiKey ?? resolveDefaultApiKey(),
       baseUrl = baseUrl ?? httpOptions?.baseUrl,
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
      final callerHeaders = Map<String, String>.from(patched.headers!);
      collapseHeaderCaseVariants(callerHeaders, 'user-agent');
      collapseHeaderCaseVariants(callerHeaders, 'x-goog-api-client');
      for (final entry in callerHeaders.entries) {
        final lower = entry.key.toLowerCase();
        if (lower == 'user-agent' || lower == 'x-goog-api-client') {
          reqHeaders.removeWhere((k, _) => k.toLowerCase() == lower);
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
      return jsonDecode(decodeResponseBody(response)) as Map<String, dynamic>;
    } else {
      throw _buildHttpError(response);
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
      return jsonDecode(decodeResponseBody(response)) as Map<String, dynamic>;
    } else {
      throw _buildHttpError(response);
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
      final decodedBody = decodeResponseBody(response);
      if (decodedBody.isEmpty) return <String, dynamic>{};
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      throw _buildHttpError(response);
    }
  }

  static GoogleGenAiError _buildHttpError(http.Response response) {
    final decodedBody = decodeResponseBody(response);
    final parsedError = ApiError.tryParseEnvelope(decodedBody);
    if (response.statusCode >= 400 && response.statusCode < 500) {
      return ApiClientError(
        statusCode: response.statusCode,
        body: decodedBody,
        error: parsedError,
      );
    }
    if (response.statusCode >= 500) {
      return ApiServerError(
        statusCode: response.statusCode,
        body: decodedBody,
        error: parsedError,
      );
    }
    return GoogleGenAiError(
      statusCode: response.statusCode,
      body: decodedBody,
      error: parsedError,
    );
  }

  /// Closes the underlying HTTP client, releasing associated resources.
  void close() {
    _httpClient.close();
  }
}

/// Buffers raw JSON stream lines until outer curly braces balance outside JSON
/// string literals.
///
/// Braces (`{` and `}`) inside double-quoted strings and escaped quotes (`\"`)
/// are ignored so multi-line JSON error or stream payloads containing literal
/// brace characters are never split prematurely.
class RawJsonLineBuffer {
  final List<String> _lines = <String>[];
  int _depth = 0;
  bool _inString = false;
  bool _escaped = false;

  /// Appends [line] to the buffer and returns the concatenated JSON payload
  /// once outer braces return to balance (`0`), or `null` if more lines are
  /// needed.
  String? addLine(String line) {
    for (var i = 0; i < line.length; i++) {
      final ch = line.codeUnitAt(i);
      if (_inString) {
        if (_escaped) {
          _escaped = false;
        } else if (ch == 0x5C) {
          // '\'
          _escaped = true;
        } else if (ch == 0x22) {
          // '"'
          _inString = false;
        }
      } else if (ch == 0x22) {
        _inString = true;
      } else if (ch == 0x7B) {
        // '{'
        _depth += 1;
      } else if (ch == 0x7D) {
        // '}'
        _depth -= 1;
      }
    }
    _lines.add(line);
    if (_depth == 0) {
      return flush();
    }
    return null;
  }

  /// Flushes and returns any remaining buffered lines, resetting parser state.
  String flush() {
    final chunk = _lines.join();
    _lines.clear();
    _depth = 0;
    _inString = false;
    _escaped = false;
    return chunk;
  }
}

/// Structured error details returned by an HTTP API error response.
class ApiError {
  /// Numeric HTTP/RPC status code or symbolic error identifier.
  final Object? code;

  /// Developer-facing error message from the backend.
  final String? message;

  /// Symbolic status code (for example, `'INVALID_ARGUMENT'`).
  final Object? status;

  /// Additional structured error details.
  final List<Map<String, dynamic>>? details;

  /// Creates an [ApiError].
  const ApiError({this.code, this.message, this.status, this.details});

  /// Creates an [ApiError] from a JSON map.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    return ApiError(
      code: json['code'],
      message: json['message'] as String?,
      status: json['status'],
      details: rawDetails is List
          ? rawDetails
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : null,
    );
  }

  /// Attempts to parse an `{"error": {...}}` JSON envelope from [body].
  static ApiError? tryParseEnvelope(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final inner = decoded['error'];
        if (inner is Map<String, dynamic>) {
          return ApiError.fromJson(inner);
        }
        if (decoded.containsKey('message') || decoded.containsKey('code')) {
          return ApiError.fromJson(decoded);
        }
      }
    } catch (_) {
      // Ignore non-JSON error bodies.
    }
    return null;
  }

  /// Serializes this [ApiError] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': ?code,
    'message': ?message,
    'status': ?status,
    'details': ?details,
  };
}

/// Base exception thrown when an HTTP request to the Google GenAI API fails.
class GoogleGenAiError implements Exception {
  /// HTTP status code of the response.
  final int statusCode;

  /// Raw HTTP response body.
  final String body;

  /// Parsed backend [ApiError] details when available.
  final ApiError? error;

  /// Developer-facing error message surfaced from [error] or [body].
  final String message;

  /// Creates a [GoogleGenAiError].
  GoogleGenAiError({
    required this.statusCode,
    required this.body,
    this.error,
    String? message,
  }) : message =
           message ??
           ((error?.message != null && error!.message!.isNotEmpty)
               ? error.message!
               : 'API Error: $statusCode $body');

  @override
  String toString() => 'Exception: API Error: $statusCode $body';
}

/// Exception thrown for 4XX client error responses from the Google GenAI API.
class ApiClientError extends GoogleGenAiError {
  /// Creates an [ApiClientError] for a 4XX HTTP response.
  ApiClientError({
    required super.statusCode,
    required super.body,
    super.error,
    super.message,
  });
}

/// Exception thrown for 5XX server error responses from the Google GenAI API.
class ApiServerError extends GoogleGenAiError {
  /// Creates an [ApiServerError] for a 5XX HTTP response.
  ApiServerError({
    required super.statusCode,
    required super.body,
    super.error,
    super.message,
  });
}
