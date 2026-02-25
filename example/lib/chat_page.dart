import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:permission_handler/permission_handler.dart';

// Importing custom widgets and data models from the project.
import 'bubble.dart'; // A widget to display a single chat message bubble.
import 'main.dart'; // Contains global variables like the API key.
import 'message.dart'; // The data class for a chat message (ChatMessage).
import 'package:record/record.dart'; // Package for recording audio.

/// Enum to manage the state of the WebSocket connection to the Gemini API.
enum ConnectionStatus { connecting, connected, disconnected }

/// Enum to define the desired response modality from the model.
enum ResponseMode { text, audio }

/// The main chat page widget.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  // --- Gemini Live API and Session Management ---
  late final GoogleGenAI _genAI; // The main instance for interacting with the Gemini API.
  LiveSession? _session; // The active WebSocket session for real-time communication.
  final TextEditingController _textController = TextEditingController(); // Controller for the text input field.

  // --- State Management Variables ---
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected; // Tracks the current connection status.
  bool _isReplying = false; // A flag to indicate if the model is currently generating a response.
  final List<ChatMessage> _messages = []; // A list to store the history of chat messages.
  ChatMessage? _streamingMessage; // A separate message object to hold the response as it streams in.
  String _statusText = "Initializing connection..."; // A user-facing string to show the current status.

  // --- Image and Audio Handling Variables ---
  XFile? _pickedImage; // Holds the image file selected by the user.
  final ImagePicker _picker = ImagePicker(); // An instance of the image picker utility.
  StreamSubscription<RecordState>? _recordSub; // Subscription to listen to the audio recorder's state changes.
  bool _isRecording = false; // A flag to track if audio is currently being recorded.

  // --- Audio and Mode Management ---
  final AudioRecorder _audioRecorder = AudioRecorder(); // The main object for handling audio recording.
  StreamSubscription<List<int>>? _audioStreamSubscription; // Subscription for an audio stream (not used in this implementation but good practice to have).
  ResponseMode _responseMode = ResponseMode.text; // The default response mode is text.
  final StringBuffer _audioBuffer = StringBuffer(); // A buffer for audio data (not used in this implementation).

  /// Initializes the connection to the Gemini Live API when the widget is first created.
  Future<void> _initialize() async {
    await _connectToLiveAPI();
  }

  @override
  void initState() {
    super.initState();
    // Initialize the GoogleGenAI instance with the API key.
    _genAI = GoogleGenAI(apiKey: geminiApiKey);
    // Start the connection process.
    _initialize();
    // Subscribe to the audio recorder's state to update the UI (e.g., change the mic icon).
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      if (mounted) {
        setState(() => _isRecording = recordState == RecordState.record);
      }
    });
  }

  @override
  void dispose() {
    // It's crucial to clean up resources to prevent memory leaks.
    _session?.close(); // Close the WebSocket connection.
    _audioStreamSubscription?.cancel(); // Cancel any active stream subscriptions.
    _audioRecorder.dispose(); // Dispose of the audio recorder.
    _textController.dispose(); // Dispose of the text controller.
    super.dispose();
  }

  /// A helper function to safely update the status text on the UI.
  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  // --- Connection Management ---
  /// Establishes a WebSocket connection to the Gemini Live API.
  Future<void> _connectToLiveAPI() async {
    // Prevent multiple connection attempts if one is already in progress.
    if (_connectionStatus == ConnectionStatus.connecting) return;

    // Safely close any pre-existing session before creating a new one.
    await _session?.close();
    setState(() {
      _session = null;
      _connectionStatus = ConnectionStatus.connecting;
      _messages.clear(); // Clear previous chat history.
      // Add a temporary message to inform the user about the connection attempt.
      _addMessage(
        ChatMessage(
          text: "Connecting to Gemini Live API (${_responseMode.name} mode)...",
          author: Role.model,
        ),
      );
      _updateStatus("Connecting to Gemini Live API...");
    });

    try {
      final modelName = 'gemini-live-2.5-flash-preview';
      // Initiate the connection with specified parameters.
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          // Specify the model to use. 'flash' is optimized for speed.
          model: modelName,
          // Configure the generation output.
          config: GenerationConfig(
            // Define the expected response format (modality).
            // This is dynamically set based on the _responseMode state.
            responseModalities: _responseMode == ResponseMode.audio
                ? [Modality.AUDIO]
                : [Modality.TEXT],
          ),
          // Provide system instructions to guide the model's behavior.
          systemInstruction: Content(
            parts: [
              Part(
                text: "You are a helpful AI assistant. "
                    "Your goal is to provide comprehensive, detailed, and well-structured answers. Always explain the background, key concepts, and provide illustrative examples. Do not give short or brief answers."
                    "**You must respond in the same language that the user uses for their question.** For example, if the user asks a question in Korean, you must reply in Korean. "
                    "If they ask in Japanese, reply in Japanese.",
              ),
            ],
          ),
          // Define callbacks to handle WebSocket events.
          callbacks: LiveCallbacks(
            onOpen: () => _updateStatus("Connection successful! Try turning on the mic."),
            onMessage: _handleLiveAPIResponse, // Called when a message is received.
            onError: (error, stack) {
              print('🚨 Error occurred: $error');
              if (mounted) {
                setState(() => _connectionStatus = ConnectionStatus.disconnected);
              }
            },
            onClose: (code, reason) {
              print('🚪 Connection closed: $code, $reason');
              if (mounted) {
                setState(() => _connectionStatus = ConnectionStatus.disconnected);
              }
            },
          ),
        ),
      );

      // If the connection is successful, update the state.
      if (mounted) {
        setState(() {
          _session = session;
          _connectionStatus = ConnectionStatus.connected;
          _messages.removeLast(); // Remove the "Connecting..." message.
          // Add a welcome message.
          _addMessage(
            ChatMessage(text: "Hello! Press the mic button to speak.", author: Role.model),
          );
        });
      }
    } catch (e) {
      print("Connection failed: $e");
      if (mounted) {
        setState(() => _connectionStatus = ConnectionStatus.disconnected);
      }
    }
  }

  // --- Message Handling ---
  /// Handles incoming messages from the Gemini Live API.
  void _handleLiveAPIResponse(LiveServerMessage message) {
    if (!mounted) return;

    final textChunk = message.text;
    print('📥 Received message textchunk: $textChunk');
    // If a text chunk is received, update the streaming message.
    if (textChunk != null) {
      setState(() {
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
      });
    }

    // When the model signals that its turn is complete, finalize the message.
    if (message.serverContent?.turnComplete ?? false) {
      setState(() {
        if (_streamingMessage != null) {
          // Move the completed streaming message into the main message list.
          _messages.add(_streamingMessage!);
          _streamingMessage = null; // Clear the streaming message.
        }
        _isReplying = false; // Allow the user to send another message.
      });
    }
  }

  /// A helper function to add a new message to the list and update the UI.
  void _addMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
  }

  // --- Multimodal Input and Sending ---
  /// Opens the image gallery for the user to pick an image.
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress image to reduce size.
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  /// Toggles audio recording on and off.
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // --- Stop Recording Logic ---
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false); // Update UI immediately.

      if (path != null) {
        print("Recording stopped. File path: $path");

        // 1. Read the recorded audio file as bytes.
        final file = File(path);
        final audioBytes = await file.readAsBytes();

        // 2. Display a message in the UI to confirm audio was sent.
        _addMessage(ChatMessage(text: "[User audio sent]", author: Role.user));

        // 3. Send the audio data to the server.
        if (_session != null) {
          setState(() => _isReplying = true);

          _session!.sendMessage(
            LiveClientMessage(
              clientContent: LiveClientContent(
                turns: [
                  Content(
                    role: "user",
                    parts: [
                      Part(
                        // The 'inlineData' field is used for sending binary data like images or audio.
                        inlineData: Blob(
                          // The MIME type must match the audio format.
                          // The `record` package with `AudioEncoder.aacLc` produces 'audio/m4a'.
                          // Adjust this if you use a different encoder (e.g., 'audio/wav' for pcm16bits).
                          mimeType: 'audio/m4a',
                          // The binary data must be Base64 encoded.
                          data: base64Encode(audioBytes),
                        ),
                      ),
                    ],
                  ),
                ],
                turnComplete: true, // Signal that this is a complete user turn.
              ),
            ),
          );
        }
        // 4. Delete the temporary audio file to save space.
        await file.delete();
      }
    } else {
      // --- Start Recording Logic ---
      // Request microphone permission before starting.
      if (await Permission.microphone.request().isGranted) {
        final tempDir = await getTemporaryDirectory();
        // Use a file extension that matches the encoder. .m4a is for AAC.
        final filePath = '${tempDir.path}/temp_audio.m4a';

        // Start recording with a configuration that matches the MIME type.
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
      } else {
        print("Microphone permission was denied.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Microphone permission is required.")));
        }
      }
    }
  }

  /// Sends a text message and/or an image to the API.
  Future<void> _sendMessage() async {
    final text = _textController.text;
    // Do not send if the input is empty, the model is replying, or the session is not active.
    if ((text.isEmpty && _pickedImage == null) || _isReplying || _session == null) {
      return;
    }

    // Add the user's message to the UI immediately for a responsive feel.
    _addMessage(
      ChatMessage(text: text, author: Role.user, image: _pickedImage),
    );

    setState(() => _isReplying = true);

    // Prepare the parts of the message to be sent.
    final List<Part> parts = [];
    if (text.isNotEmpty) {
      parts.add(Part(text: text));
    }
    if (_pickedImage != null) {
      final imageBytes = await _pickedImage!.readAsBytes();
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
    _session!.sendMessage(
      LiveClientMessage(
        clientContent: LiveClientContent(
          turns: [Content(role: "user", parts: parts)],
          turnComplete: true,
        ),
      ),
    );

    // Clear the input fields after sending.
    _textController.clear();
    setState(() => _pickedImage = null);
  }

  /// Builds the text input composer with buttons for image, audio, and sending.
  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Show a preview of the picked image.
          if (_pickedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      // Button to remove the selected image.
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                        onPressed: () => setState(() => _pickedImage = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              // Button to pick an image.
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _pickImage,
              ),
              // Button to toggle audio recording.
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
                ),
                color: _isRecording ? Colors.red : Theme.of(context).iconTheme.color,
                onPressed: _toggleRecording,
              ),
              // The main text input field.
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Enter a message or image description',
                  ),
                ),
              ),
              // Button to send the message.
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an alternative input area, primarily for voice input.
  /// Note: This widget is not used in the current `build` method logic but is available.
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _toggleRecording,
            backgroundColor: _isRecording ? Colors.red.shade400 : Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? Colors.white : Theme.of(context).colorScheme.onSecondaryContainer,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Widget Builder ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Live API'),
        actions: [
          // A menu to select the desired response mode (Text or Audio).
          PopupMenuButton<ResponseMode>(
            onSelected: (ResponseMode mode) {
              if (mode != _responseMode) {
                setState(() => _responseMode = mode);
                // Reconnect to the API with the new mode setting.
                _connectToLiveAPI();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ResponseMode>>[
              const PopupMenuItem<ResponseMode>(
                value: ResponseMode.text,
                child: Text('Text Response'),
              ),
              // Add this back if you implement audio response playback.
              // const PopupMenuItem<ResponseMode>(
              //   value: ResponseMode.audio,
              //   child: Text('Audio Response'),
              // ),
            ],
            icon: Icon(
              _responseMode == ResponseMode.text ? Icons.text_fields : Icons.graphic_eq,
            ),
          ),
          // A visual indicator for the connection status.
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.circle,
              color: _connectionStatus == ConnectionStatus.connected
                  ? Colors.green
                  : _connectionStatus == ConnectionStatus.connecting
                  ? Colors.orange
                  : Colors.red,
              size: 16,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // The main chat area.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true, // Shows the latest messages at the bottom.
                // The item count includes the streaming message if it exists.
                itemCount: _messages.length + (_streamingMessage == null ? 0 : 1),
                itemBuilder: (context, index) {
                  // If there's a streaming message, render it at the top (index 0).
                  if (_streamingMessage != null && index == 0) {
                    return Bubble(message: _streamingMessage!);
                  }
                  // Adjust the index to access the main messages list.
                  final messageIndex = index - (_streamingMessage == null ? 0 : 1);
                  final message = _messages.reversed.toList()[messageIndex];
                  return Bubble(message: message);
                },
              ),
            ),
            // Show a progress bar while the model is replying.
            if (_isReplying) const LinearProgressIndicator(),
            const Divider(height: 1.0),
            // If disconnected, show a button to reconnect.
            if (_connectionStatus == ConnectionStatus.disconnected)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reconnect"),
                  onPressed: _connectToLiveAPI,
                ),
              ),
            // If connected, show the message input composer.
            if (_connectionStatus == ConnectionStatus.connected)
              _buildTextComposer(),
          ],
        ),
      ),
    );
  }
}
