import 'package:http/http.dart' as http;

import 'auth_tokens_service.dart';
import 'client/api_client.dart';
import 'live_service.dart';
import 'model/models.dart';
import 'music_service.dart';
import 'voices_service.dart';

// Re-export key classes from the live service module.
// This allows users to access LiveCallbacks, LiveConnectParameters, and LiveSession
// directly by importing this main library file, simplifying the public API.
export 'live_service.dart'
    show
        LiveCallbacks,
        LiveConnectParameters,
        LiveSession,
        LiveService,
        TimeoutException;

// Re-export realtime music (Lyria Live) classes.
export 'music_service.dart'
    show
        LiveMusicCallbacks,
        LiveMusicConnectParameters,
        LiveMusicSession,
        LiveMusicService;

// Re-export ephemeral auth tokens service.
export 'auth_tokens_service.dart' show AuthTokensService;

// Re-export all model classes (e.g., Content, Part, GenerateContentResponse).
// This provides a single, convenient import for all data structures
// used by the API.
export 'model/models.dart';

// Re-export voices service for managing custom voices.
export 'voices_service.dart';

/// The primary class for interacting with the Google Generative AI API.
///
/// An instance of this class is the main entry point for all API functionality.
///
/// Example usage:
/// ```dart
/// final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY');
/// // Use genAI to access different services, like the chat model.
/// // final model = genAI.generativeModel(model: 'gemini-pro');
/// // final response = await model.generateContent([Content.text('Tell me a joke.')]);
/// // print(response.text);
/// ```
class GoogleGenAI {
  /// The API key used to authenticate requests.
  final String apiKey;

  /// API version used by the live module.
  final String apiVersion;

  /// Optional client-level HTTP and WebSocket transport options (`baseUrl`,
  /// `apiVersion`, `headers`).
  final HttpOptions? httpOptions;

  /// An optional custom HTTP client for making network requests.
  ///
  /// This is useful for advanced scenarios, such as:
  /// - Using a mock client for testing.
  /// - Configuring a proxy.
  /// - Setting custom timeouts or headers.
  ///
  /// If not provided, a default `http.Client` will be created internally.
  final http.Client? httpClient;

  /// The internal low-level client responsible for making API requests.
  ///
  /// This is marked as `late` because it is initialized in the constructor.
  late final ApiClient _apiClient;

  /// Provides access to the live, streaming services of the API.
  ///
  /// This is marked as `late` because it is initialized in the constructor.
  late final LiveService live;

  /// Provides access to the Gemini Voices API for managing custom and prebuilt voices.
  ///
  /// This is marked as `late` because it is initialized in the constructor.
  late final GeminiVoicesService voices;

  /// Provides access to ephemeral token generation for Live API connections.
  ///
  /// This is marked as `late` because it is initialized in the constructor.
  late final AuthTokensService authTokens;

  /// Provides access to the Realtime Music generation (Lyria Live) service.
  LiveMusicService get music => live.music;

  /// An optional logger function to receive WebSocket traffic and connection logs.
  ///
  /// For example, pass `print` to log all WebSocket messages to the console,
  /// or pass a custom logging function.
  final void Function(String message)? logger;

  /// Creates a new instance of the [GoogleGenAI] client.
  ///
  /// [apiKey] is your Google AI API key, which is required for all requests.
  /// [httpClient] is an optional client to use for making HTTP requests.
  /// [httpOptions] is an optional [HttpOptions] or `Map<String, dynamic>` for
  /// configuring `baseUrl`, `apiVersion`, and default `headers`.
  /// [logger] is an optional logging callback for network & WebSocket events.
  GoogleGenAI({
    required this.apiKey,
    this.httpClient,
    String apiVersion = 'v1beta',
    Object? httpOptions,
    this.logger,
  }) : httpOptions = _parseHttpOptions(httpOptions),
       apiVersion = _parseHttpOptions(httpOptions)?.apiVersion ?? apiVersion {
    // Initialize the internal API client with the provided credentials and HTTP client.
    _apiClient = ApiClient(
      apiKey: apiKey,
      baseUrl: this.httpOptions?.baseUrl,
      apiVersion: this.apiVersion,
      headers: this.httpOptions?.headers,
      httpClient: httpClient,
    );

    // Initialize the LiveService, which handles real-time interactions.
    live = LiveService(
      apiKey: apiKey,
      apiVersion: this.apiVersion,
      httpOptions: this.httpOptions,
      logger: logger,
    );

    // Initialize the VoicesService for custom and system voice operations.
    voices = GeminiVoicesService.fromApiClient(_apiClient);

    // Initialize the AuthTokensService for ephemeral token generation.
    authTokens = AuthTokensService(_apiClient);
  }

  static HttpOptions? _parseHttpOptions(Object? value) {
    if (value == null) return null;
    if (value is HttpOptions) return value;
    if (value is Map<String, dynamic>) {
      return HttpOptions.fromJson(value);
    }
    throw ArgumentError.value(
      value,
      'httpOptions',
      'Must be an HttpOptions or Map<String, dynamic>.',
    );
  }

  /// Releases any resources held by the client.
  ///
  /// It is important to call this method when the [GoogleGenAI] instance is no
  /// longer needed to prevent resource leaks. This is especially crucial if an
  /// internal `httpClient` was created, as this method ensures it is properly closed.
  void close() {
    _apiClient.close();
  }
}
