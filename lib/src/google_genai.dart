/// The main entry point for the Google Generative AI Dart SDK.
///
/// This library provides a high-level interface to the Google Generative AI
/// API, making it easy to integrate generative AI models into your Dart
/// and Flutter applications.

import 'package:http/http.dart' as http;

import 'client/api_client.dart';
import 'live_service.dart';

// Re-export key classes from the live service module.
// This allows users to access LiveCallbacks, LiveConnectParameters, and LiveSession
// directly by importing this main library file, simplifying the public API.
export 'live_service.dart'
    show LiveCallbacks, LiveConnectParameters, LiveSession;

// Re-export all model classes (e.g., Content, Part, GenerateContentResponse).
// This provides a single, convenient import for all data structures
// used by the API.
export 'model/models.dart';
export 'model/google_models.dart';
export 'schema.dart';

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

  /// Creates a new instance of the [GoogleGenAI] client.
  ///
  /// [apiKey] is your Google AI API key, which is required for all requests.
  /// [httpClient] is an optional client to use for making HTTP requests.
  GoogleGenAI({required this.apiKey, this.httpClient}) {
    // Initialize the internal API client with the provided credentials and HTTP client.
    _apiClient = ApiClient(apiKey: apiKey, httpClient: httpClient);

    // Initialize the LiveService, which handles real-time interactions.
    live = LiveService(apiKey: apiKey);
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