import 'dart:async';
import 'dart:convert';

import 'package:example/api_key_store.dart';
import 'package:example/example_debug_log.dart';
import 'package:example/live_api_defaults.dart';
import 'package:example/message.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../data/services/chat_audio_service.dart';
import '../../../data/services/chat_image_service.dart';
import '../../../data/services/chat_live_service.dart';
import '../../../data/services/chat_recorder_service.dart';
import '../../../domain/chat_log_format.dart';
import '../../../domain/models/connection_status.dart';
import '../../../domain/models/response_mode.dart';

/// State + logic for the chat screen.
///
/// The view model never touches a `BuildContext`; it asks the view to show a
/// transient message via [onNotice] and to clear the text field via
/// [onClearInput].
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    ChatLiveService? liveService,
    ChatAudioService? audioService,
    ChatRecorderService? recorderService,
    ChatImageService? imageService,
  }) : _live = liveService ?? ChatLiveService(),
       _responseAudioPlayer = audioService ?? ChatAudioService(),
       _audioRecorder = recorderService ?? ChatRecorderService(),
       _imageService = imageService ?? ChatImageService();

  final ChatLiveService _live;
  final ChatAudioService _responseAudioPlayer;
  final ChatRecorderService _audioRecorder;
  final ChatImageService _imageService;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(String message)? onNotice;

  /// Clear the text input field.
  VoidCallback? onClearInput;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // --- Gemini Live API and Session Management ---
  LiveSession?
  _session; // The active WebSocket session for real-time communication.

  // --- State Management Variables ---
  ConnectionStatus _connectionStatus =
      ConnectionStatus.disconnected; // Tracks the current connection status.
  bool _isReplying =
      false; // A flag to indicate if the model is currently generating a response.
  final List<ChatMessage> _messages =
      []; // A list to store the history of chat messages.
  ChatMessage?
  _streamingMessage; // A separate message object to hold the response as it streams in.

  // --- Image and Audio Handling Variables ---
  XFile? _pickedImage; // Holds the image file selected by the user.
  Uint8List?
  _pickedImageBytes; // Holds in-memory bytes of the picked image for cross-platform rendering.
  StreamSubscription<RecordState>?
  _recordSub; // Subscription to listen to the audio recorder's state changes.
  bool _isRecording =
      false; // A flag to track if audio is currently being recorded.

  // --- Audio and Mode Management ---
  StreamSubscription<List<int>>?
  _audioStreamSubscription; // Subscription for an audio stream (not used in this implementation but good practice to have).
  late final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: ApiKeyStore.liveModel,
  );
  ResponseMode _responseMode = ResponseMode.text;
  int _audioPlaybackCommand = 0;
  String? _activeAudioMessageId;
  String? _autoplayAudioMessageId;
  int _currentResponseAudioChunkCount = 0;
  int _sessionLifecycleVersion = 0;

  // --- Read-only view state ---
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isReplying => _isReplying;
  List<ChatMessage> get messages => _messages;
  ChatMessage? get streamingMessage => _streamingMessage;
  XFile? get pickedImage => _pickedImage;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  bool get isRecording => _isRecording;
  GeminiTokenUsageTracker get usageTracker => _usageTracker;
  ResponseMode get responseMode => _responseMode;
  int get audioPlaybackCommand => _audioPlaybackCommand;
  String? get activeAudioMessageId => _activeAudioMessageId;
  String? get autoplayAudioMessageId => _autoplayAudioMessageId;

  bool get voiceModeEnabled => _responseMode == ResponseMode.audio;

  bool _canApplySessionUpdate(int version) =>
      !_isDisposed && version == _sessionLifecycleVersion;

  void _invalidateSessionCallbacks() {
    _sessionLifecycleVersion += 1;
  }

  void _updateAudioPlaybackTarget({String? messageId, bool autoplay = false}) {
    _activeAudioMessageId = messageId;
    _autoplayAudioMessageId = autoplay ? messageId : null;
    _audioPlaybackCommand += 1;
  }

  void clearAutoPlayRequest(String messageId) {
    if (_isDisposed || _autoplayAudioMessageId != messageId) return;
    _autoplayAudioMessageId = null;
    notifyListeners();
  }

  void _stopAllBubblePlayback() {
    final hadActivePlayback = _activeAudioMessageId != null;
    if (_isDisposed) return;
    _updateAudioPlaybackTarget();
    notifyListeners();
    if (hadActivePlayback) {
      logExampleEvent(
        'CHAT',
        'Stopped active voice playback before a new interaction.',
      );
    }
  }

  void requestBubblePlayback(String messageId) {
    if (_isDisposed) return;
    _updateAudioPlaybackTarget(messageId: messageId);
    notifyListeners();
    logExampleEvent(
      'CHAT',
      'Voice playback target changed to message $messageId.',
    );
  }

  /// Initializes the connection to the Gemini Live API when the screen is
  /// first created.
  Future<void> _initialize() async {
    await connectToLiveAPI();
  }

  /// Starts the connection process and subscribes to the recorder state.
  void init() {
    // Start the connection process.
    _initialize();
    // Subscribe to the audio recorder's state to update the UI (e.g., change the mic icon).
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      if (!_isDisposed) {
        _isRecording = recordState == RecordState.record;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    // It's crucial to clean up resources to prevent memory leaks.
    _isDisposed = true;
    _invalidateSessionCallbacks();
    final session = _session;
    _session = null;
    unawaited(session?.close() ?? Future<void>.value());
    _recordSub?.cancel();
    _audioStreamSubscription
        ?.cancel(); // Cancel any active stream subscriptions.
    _audioRecorder.dispose(); // Dispose of the audio recorder.
    unawaited(_responseAudioPlayer.dispose());
    _usageTracker.dispose();
    super.dispose();
  }

  // --- Connection Management ---
  /// Establishes a WebSocket connection to the Gemini Live API.
  Future<void> connectToLiveAPI() async {
    // Prevent multiple connection attempts if one is already in progress.
    if (_connectionStatus == ConnectionStatus.connecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _session = null;
      _connectionStatus = ConnectionStatus.disconnected;
      _messages.clear();
      notifyListeners();
      _addMessage(
        ChatMessage(
          text:
              "Gemini API key is not configured. Go back and open Settings on the home screen.",
          author: Role.model,
        ),
      );
      return;
    }

    // Safely close any pre-existing session before creating a new one.
    final previousSession = _session;
    _session = null;
    _invalidateSessionCallbacks();
    final connectVersion = _sessionLifecycleVersion;
    await previousSession?.close();
    if (!_canApplySessionUpdate(connectVersion)) return;
    await _responseAudioPlayer.stop();
    logExampleEvent(
      'CHAT',
      'Connecting to Gemini Live API in ${voiceModeEnabled ? "voice" : "text"} mode.',
    );
    _session = null;
    _connectionStatus = ConnectionStatus.connecting;
    _streamingMessage = null;
    _isReplying = false;
    _pickedImage = null;
    _pickedImageBytes = null;
    _updateAudioPlaybackTarget();
    _usageTracker.reset();
    _messages.clear(); // Clear previous chat history.
    // Add a temporary message to inform the user about the connection attempt.
    _addMessage(
      ChatMessage(
        text: voiceModeEnabled
            ? "Connecting to Gemini Live API (voice mode)..."
            : "Connecting to Gemini Live API (text mode)...",
        author: Role.model,
      ),
    );

    try {
      // Initiate the connection with specified parameters.
      final session = await _live.connect(
        LiveCallbacks(
          onOpen: () {},
          onMessage: (message) {
            if (!_canApplySessionUpdate(connectVersion)) return;
            _handleLiveAPIResponse(message);
          },
          onError: (error, stack) {
            if (!_canApplySessionUpdate(connectVersion)) return;
            unawaited(_responseAudioPlayer.stop());
            logExampleEvent('CHAT', 'Live session error: $error');
            if (_canApplySessionUpdate(connectVersion)) {
              _connectionStatus = ConnectionStatus.disconnected;
              _updateAudioPlaybackTarget();
              notifyListeners();
            }
          },
          onClose: (code, reason) {
            if (!_canApplySessionUpdate(connectVersion)) return;
            unawaited(_responseAudioPlayer.stop());
            logExampleEvent(
              'CHAT',
              'Live session closed: code=$code, reason=$reason',
            );
            if (_canApplySessionUpdate(connectVersion)) {
              _connectionStatus = ConnectionStatus.disconnected;
              _updateAudioPlaybackTarget();
              notifyListeners();
            }
          },
        ),
      );

      // If the connection is successful, update the state.
      if (_canApplySessionUpdate(connectVersion)) {
        _session = session;
        _connectionStatus = ConnectionStatus.connected;
        _messages.removeLast(); // Remove the "Connecting..." message.
        // Add a welcome message.
        _addMessage(
          ChatMessage(
            text: voiceModeEnabled
                ? "Hello! Voice mode is on. Press the mic button to speak. Responses appear as live transcripts."
                : "Hello! Text mode is on. Type a message or attach an image. Responses appear as live transcripts.",
            author: Role.model,
          ),
        );
        notifyListeners();
        logExampleEvent('CHAT', 'Live session connected.');
      }
    } catch (e) {
      logExampleEvent('CHAT', 'Connection failed: $e');
      if (_canApplySessionUpdate(connectVersion)) {
        _connectionStatus = ConnectionStatus.disconnected;
        if (_messages.isNotEmpty &&
            _messages.last.text.startsWith('Connecting to Gemini Live API')) {
          _messages.removeLast();
        }
        _addMessage(
          ChatMessage(
            text:
                "Failed to connect to Gemini Live API: $e\nPlease check your API key or model in Settings.",
            author: Role.model,
          ),
        );
        notifyListeners();
      }
    }
  }

  // --- Message Handling ---
  /// Handles incoming messages from the Gemini Live API.
  void _handleLiveAPIResponse(LiveServerMessage message) {
    if (_isDisposed) return;
    _usageTracker.recordMessage(message);

    final serverContent = message.serverContent;
    final turnFinished =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);
    final hadPendingResponse =
        _isReplying ||
        _streamingMessage != null ||
        _currentResponseAudioChunkCount > 0;

    if (serverContent?.interrupted ?? false) {
      _responseAudioPlayer.clear();
      _currentResponseAudioChunkCount = 0;
      logExampleEvent('CHAT', 'Server interrupted the current audio response.');
    }

    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      logExampleEvent('CHAT', 'Received message text chunk: $textChunk');
    }
    if (message.data != null) {
      _responseAudioPlayer.appendBase64Chunk(message.data!);
      _currentResponseAudioChunkCount += 1;
      if (_currentResponseAudioChunkCount == 1) {
        logExampleEvent('CHAT', 'Started receiving audio response chunks.');
      }
    }
    // If a text chunk is received, update the streaming message.
    if (textChunk != null) {
      if (_streamingMessage == null) {
        // If this is the first chunk, create a new streaming message.
        _streamingMessage = ChatMessage(text: textChunk, author: Role.model);
      } else {
        // Otherwise, append the new chunk to the existing message text.
        _streamingMessage = ChatMessage(
          text: _streamingMessage!.text + textChunk,
          author: Role.model,
        );
      }
      notifyListeners();
    }

    // When the model signals that its turn is complete, finalize the message.
    if (turnFinished) {
      if (_currentResponseAudioChunkCount > 0) {
        logExampleEvent(
          'CHAT',
          'Completed response with $_currentResponseAudioChunkCount audio chunks buffered.',
        );
      } else if (voiceModeEnabled && hadPendingResponse) {
        logExampleEvent(
          'CHAT',
          'Turn finished without any buffered audio data.',
        );
      }
      final responseAudio = _responseAudioPlayer.takeBufferedClip(
        autoPlay: voiceModeEnabled,
      );
      ChatMessage? completedMessage;
      if (_streamingMessage != null) {
        completedMessage = _streamingMessage!.copyWith(audio: responseAudio);
      } else if (responseAudio != null) {
        completedMessage = ChatMessage(
          text: '',
          author: Role.model,
          audio: responseAudio,
        );
      }
      if (completedMessage != null) {
        final finalizedMessage = completedMessage;
        _messages.add(finalizedMessage);
        if (responseAudio != null && voiceModeEnabled) {
          _updateAudioPlaybackTarget(
            messageId: finalizedMessage.id,
            autoplay: true,
          );
          logExampleEvent(
            'CHAT',
            'Voice response is ready for auto-play on message ${finalizedMessage.id}.',
          );
        }
      }
      _streamingMessage = null; // Clear the streaming message.
      _isReplying = false; // Allow the user to send another message.
      notifyListeners();
      _currentResponseAudioChunkCount = 0;
    }
  }

  /// A helper function to add a new message to the list and update the UI.
  void _addMessage(ChatMessage message) {
    if (_isDisposed) return;
    _messages.add(message);
    notifyListeners();
  }

  // --- Multimodal Input and Sending ---
  /// Opens the image gallery for the user to pick an image.
  Future<void> pickImage() async {
    logExampleEvent('CHAT', 'Opening image picker.');
    try {
      final XFile? image = await _imageService.pickFromGallery();
      if (image != null && !_isDisposed) {
        final bytes = await image.readAsBytes();
        _pickedImage = image;
        _pickedImageBytes = bytes;
        notifyListeners();
        logExampleEvent(
          'CHAT',
          'Selected image: ${image.path} (${bytes.length} bytes)',
        );
      }
    } catch (error) {
      logExampleEvent('CHAT', 'Image picker failed: $error');
      if (_isDisposed) return;
      onNotice?.call('Image selection failed. Check platform permissions.');
    }
  }

  /// Removes the currently selected image.
  void clearPickedImage() {
    _pickedImage = null;
    _pickedImageBytes = null;
    notifyListeners();
  }

  /// Toggles audio recording on and off.
  Future<void> toggleRecording() async {
    if (_isRecording) {
      // --- Stop Recording Logic ---
      final path = await _audioRecorder.stop();
      _isRecording = false; // Update UI immediately.
      notifyListeners();
      logExampleEvent('CHAT', 'Stopped voice recording.');

      if (path != null) {
        logExampleEvent('CHAT', 'Recorded voice input saved at: $path');

        // 1. Read the recorded audio file as bytes.
        final Uint8List audioBytes = await _audioRecorder.readRecordedBytes(
          path,
        );

        _stopAllBubblePlayback();
        _currentResponseAudioChunkCount = 0;

        // 2. Display a message in the UI to confirm audio was sent.
        _addMessage(
          ChatMessage(
            text: "[Voice input sent]",
            author: Role.user,
            audio: ChatAudioClip.file(
              filePath: path,
              label: 'Your voice input',
            ),
          ),
        );

        // 3. Send the audio data to the server.
        if (_session != null) {
          _isReplying = true;
          notifyListeners();
          logExampleEvent(
            'CHAT',
            'Sending recorded voice input (${audioBytes.length} bytes).',
          );

          final mimeType = kIsWeb ? 'audio/wav' : 'audio/m4a';

          _live.sendUserTurn(_session!, [
            Part(
              inlineData: Blob(
                mimeType: mimeType,
                data: base64Encode(audioBytes),
              ),
            ),
          ]);
        }
      }
    } else {
      // --- Start Recording Logic ---
      try {
        if (await _audioRecorder.hasPermission()) {
          final String filePath = await _audioRecorder.createRecordingPath();

          InputDevice? selectedDevice;
          if (ApiKeyStore.audioDeviceId.isNotEmpty) {
            try {
              final devs = await _audioRecorder.listInputDevices();
              selectedDevice = devs
                  .where((d) => d.id == ApiKeyStore.audioDeviceId)
                  .firstOrNull;
            } catch (_) {}
          }

          // Start recording with a configuration that matches the MIME type.
          await _audioRecorder.start(device: selectedDevice, path: filePath);
          logExampleEvent('CHAT', 'Started voice recording.');
        } else {
          logExampleEvent('CHAT', 'Microphone permission was denied.');
          if (!_isDisposed) {
            onNotice?.call(
              '마이크 권한이 필요합니다. macOS [시스템 설정 > 개인정보 보호 및 보안 > 마이크]에서 앱을 허용해 주세요.',
            );
          }
        }
      } catch (e) {
        logExampleEvent('ERROR', 'Failed to start voice recording: $e');
        if (!_isDisposed) {
          onNotice?.call("마이크 녹음 오류: $e");
        }
      }
    }
  }

  /// Sends a text message and/or an image to the API.
  Future<void> sendMessage(String text) async {
    // Do not send if the input is empty, the model is replying, or the session is not active.
    if ((text.isEmpty && _pickedImage == null) ||
        _isReplying ||
        _session == null) {
      return;
    }

    _stopAllBubblePlayback();
    _currentResponseAudioChunkCount = 0;
    logExampleEvent(
      'CHAT',
      'Sending user message: text="${summarizeTextForLog(text)}", imageAttached=${_pickedImage != null}',
    );

    // Add the user's message to the UI immediately for a responsive feel.
    _addMessage(
      ChatMessage(
        text: text,
        author: Role.user,
        image: _pickedImage,
        imageBytes: _pickedImageBytes,
      ),
    );

    _isReplying = true;
    notifyListeners();

    // Prepare the parts of the message to be sent.
    final List<Part> parts = [];
    if (text.isNotEmpty) {
      parts.add(Part(text: text));
    }
    if (_pickedImage != null) {
      final imageBytes = _pickedImageBytes ?? await _pickedImage!.readAsBytes();
      parts.add(
        Part(
          inlineData: Blob(
            mimeType: 'image/jpeg',
            data: base64Encode(imageBytes),
          ),
        ),
      );
    }

    // Send the message to the Gemini API.
    _live.sendUserTurn(_session!, parts);

    // Clear the input fields after sending.
    onClearInput?.call();
    _pickedImage = null;
    _pickedImageBytes = null;
    notifyListeners();
  }

  /// Switches between text and voice mode and reconnects.
  void selectMode(ResponseMode mode) {
    if (mode == _responseMode) return;
    if (_isRecording) {
      _audioRecorder.stop();
    }
    logExampleEvent(
      'CHAT',
      'Switching chat mode to ${mode == ResponseMode.audio ? "voice" : "text"}.',
    );
    _responseMode = mode;
    _isRecording = false;
    notifyListeners();
    connectToLiveAPI();
  }
}
