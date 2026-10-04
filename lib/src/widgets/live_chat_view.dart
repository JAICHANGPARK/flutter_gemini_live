import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../google_genai.dart';
import '../utils/live_logger.dart';
import '../utils/live_session_controller.dart';
import 'live_mic_button.dart';
import 'live_status_badge.dart';
import 'live_waveform.dart';

/// Builder signature for custom user and model chat bubbles.
typedef GeminiLiveBubbleBuilder = Widget Function(
  BuildContext context,
  LiveTranscriptItem transcript,
  bool isUser,
);

/// Builder signature for a completely custom chat input area.
typedef GeminiLiveInputBuilder = Widget Function(
  BuildContext context,
  GeminiLiveSessionController controller,
  TextEditingController textController,
  VoidCallback onSend,
);

/// Builder signature for custom header/appBar content.
typedef GeminiLiveHeaderBuilder = PreferredSizeWidget? Function(
  BuildContext context,
  GeminiLiveSessionController controller,
);

/// Builder signature for the empty state when no messages exist yet.
typedef GeminiLiveEmptyBuilder = Widget Function(
  BuildContext context,
  GeminiLiveSessionController controller,
);

/// A complete, production-ready, pluggable Gemini Live chat screen widget.
///
/// Provides zero-boilerplate real-time voice and multimodal text chat with Google's
/// Gemini Live API. Users can either supply an [apiKey] directly (letting the widget
/// manage connection lifecycle automatically) or inject an existing [controller].
///
/// ### Slot Customization
/// Every visual section can be swapped with custom widgets using builder callbacks:
/// - [userBubbleBuilder] & [modelBubbleBuilder]: Custom bubbles for messages.
/// - [bubbleBuilder]: Unified bubble builder for both user and model.
/// - [inputBuilder]: Custom text/voice input bar at the bottom.
/// - [headerBuilder]: Custom app bar or header widget.
/// - [emptyBuilder]: Custom placeholder when conversation is empty.
/// - [streamingIndicatorBuilder]: Custom in-flight thinking or speech indicator.
class GeminiLiveChatView extends StatefulWidget {
  /// The Google Gemini API key. Required unless [controller] is provided.
  final String? apiKey;

  /// The Gemini model name. Defaults to [LiveModels.gemini38Live].
  final String model;

  /// Generation configuration options (voice persona, temperature, etc.).
  final GenerationConfig? config;

  /// System instructions defining model persona and behavior.
  ///
  /// Following the official Google GenAI SDK pattern (such as `@google/genai`),
  /// this accepts either a plain [String] or a structured [Content] object.
  /// If null, defaults to [defaultSystemInstruction].
  final Object? systemInstruction;

  /// Default system instruction applied when [systemInstruction] is omitted or null.
  static final Content defaultSystemInstruction = Content(
    role: 'system',
    parts: [
      Part(
        text:
            'You are a helpful, friendly, and concise real-time voice and multimodal AI assistant. '
            'Keep your responses conversational, natural, and direct.',
      ),
    ],
  );

  /// Optional tools available to the model (Google Search, function calling).
  final List<Tool>? tools;

  /// Optional pre-existing [GeminiLiveSessionController].
  /// If null, an internal controller is instantiated and managed automatically.
  final GeminiLiveSessionController? controller;

  /// Whether to automatically connect upon widget initialization. Defaults to `true`.
  final bool autoConnect;

  /// Custom builder for user message bubbles.
  final GeminiLiveBubbleBuilder? userBubbleBuilder;

  /// Custom builder for model AI message bubbles.
  final GeminiLiveBubbleBuilder? modelBubbleBuilder;

  /// Unified custom bubble builder for both user and model.
  final GeminiLiveBubbleBuilder? bubbleBuilder;

  /// Custom builder for the bottom message input area.
  final GeminiLiveInputBuilder? inputBuilder;

  /// Custom builder for the screen header / AppBar.
  final GeminiLiveHeaderBuilder? headerBuilder;

  /// Custom builder for when the chat history is empty.
  final GeminiLiveEmptyBuilder? emptyBuilder;

  /// Custom builder for active streaming/speaking indicator.
  final Widget Function(BuildContext context, bool isModelSpeaking)?
      streamingIndicatorBuilder;

  /// Callback when the user taps the image / attachment button.
  /// If null, default attachment button is omitted unless custom builder provides it.
  final Future<void> Function(BuildContext context, GeminiLiveSessionController controller)?
      onAttachPressed;

  /// Optional callback invoked when the user taps the connect call button in the AppBar.
  final VoidCallback? onConnectPressed;

  /// Optional callback invoked when the user taps the disconnect call button in the AppBar.
  final VoidCallback? onDisconnectPressed;

  /// Optional callback invoked when the user taps the stop response button.
  final VoidCallback? onStopSpeakingPressed;

  /// Whether to show the phone connect/disconnect action button in the AppBar. Defaults to `true`.
  final bool showConnectionButton;

  /// Background color or surface styling for the chat view.
  final Color? backgroundColor;

  /// Title string displayed on the default AppBar. Defaults to `'Gemini Live'`.
  final String title;

  /// Whether to show the default status badge in the AppBar. Defaults to `true`.
  final bool showStatusBadge;

  /// Whether to show real-time live waveform indicator during voice interaction. Defaults to `true`.
  final bool showWaveform;

  /// Input hint text for the text field. Defaults to `'Ask Gemini Live...'`.
  final String inputHint;

  /// Whether to enable structured console logging in debug mode. Defaults to `false`.
  final bool debugLogging;

  /// Optional custom logger or callback function for detailed network/lifecycle logging.
  /// Accepts either a [GeminiLiveLogger] instance or a standard `void Function(String)` callback.
  final Object? logger;

  /// Creates a pluggable Gemini Live chat screen widget.
  const GeminiLiveChatView({
    super.key,
    this.apiKey,
    this.model = LiveModels.gemini38Live,
    this.config,
    this.systemInstruction,
    this.tools,
    this.controller,
    this.autoConnect = true,
    this.userBubbleBuilder,
    this.modelBubbleBuilder,
    this.bubbleBuilder,
    this.inputBuilder,
    this.headerBuilder,
    this.emptyBuilder,
    this.streamingIndicatorBuilder,
    this.onAttachPressed,
    this.onConnectPressed,
    this.onDisconnectPressed,
    this.onStopSpeakingPressed,
    this.showConnectionButton = true,
    this.backgroundColor,
    this.title = 'Gemini Live',
    this.showStatusBadge = true,
    this.showWaveform = true,
    this.inputHint = 'Ask Gemini Live...',
    this.debugLogging = false,
    this.logger,
  })  : assert(
          apiKey != null || controller != null,
          'Either apiKey or controller must be provided to GeminiLiveChatView.',
        ),
        assert(
          systemInstruction == null ||
              systemInstruction is String ||
              systemInstruction is Content,
          'systemInstruction must be either a String or a Content instance.',
        ),
        assert(
          logger == null ||
              logger is GeminiLiveLogger ||
              logger is void Function(String),
          'logger must be either a GeminiLiveLogger or a void Function(String) callback.',
        );

  @override
  State<GeminiLiveChatView> createState() => _GeminiLiveChatViewState();
}

class _GeminiLiveChatViewState extends State<GeminiLiveChatView> {
  late final GeminiLiveSessionController _controller;
  late final bool _ownsController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecordingMic = false;
  Uint8List? _attachedImageBytes;
  String? _attachedImageMimeType;

  /// Attaches an image to the pending turn message.
  void attachImage(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
    setState(() {
      _attachedImageBytes = bytes;
      _attachedImageMimeType = mimeType;
    });
  }

  /// Clears the attached image preview.
  void clearAttachedImage() {
    setState(() {
      _attachedImageBytes = null;
      _attachedImageMimeType = null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      void Function(String message)? effectiveLogger;
      if (widget.logger is GeminiLiveLogger) {
        effectiveLogger = (widget.logger as GeminiLiveLogger).toCallback();
      } else if (widget.logger is void Function(String)) {
        effectiveLogger = widget.logger as void Function(String);
      } else if (widget.debugLogging) {
        effectiveLogger = const GeminiLiveLogger().toCallback();
      }

      final genAI = GoogleGenAI(
        apiKey: widget.apiKey!,
        logger: effectiveLogger,
      );
      _controller = GeminiLiveSessionController(liveService: genAI.live);
      _ownsController = true;
    }

    _controller.addListener(_onControllerUpdate);

    if (widget.autoConnect && !_controller.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connectSession();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_ownsController) {
      _controller.dispose();
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connectSession() async {
    try {
      final Content effectiveSystemInstruction;
      final rawInstruction = widget.systemInstruction;
      if (rawInstruction is String) {
        effectiveSystemInstruction = Content(
          role: 'system',
          parts: [Part(text: rawInstruction)],
        );
      } else if (rawInstruction is Content) {
        effectiveSystemInstruction = rawInstruction;
      } else {
        effectiveSystemInstruction = GeminiLiveChatView.defaultSystemInstruction;
      }

      await _controller.connect(
        LiveConnectParameters(
          model: widget.model,
          config: widget.config,
          systemInstruction: effectiveSystemInstruction,
          tools: widget.tools,
          callbacks: LiveCallbacks(
            onError: (err, st) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gemini Live error: $err')),
                );
              }
            },
          ),
        ),
      );
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    final hasImage = _attachedImageBytes != null && _attachedImageBytes!.isNotEmpty;
    if (text.isEmpty && !hasImage) return;

    final imageBytes = _attachedImageBytes;
    final imageMime = _attachedImageMimeType ?? 'image/jpeg';

    _textController.clear();
    setState(() {
      _attachedImageBytes = null;
      _attachedImageMimeType = null;
    });

    if (hasImage) {
      _controller.sendRealtimeTurn(
        text: text.isNotEmpty ? text : null,
        imageBytes: imageBytes,
        imageMimeType: imageMime,
      );
    } else {
      _controller.sendRealtimeText(text);
    }
  }

  void _handleToggleConnection() {
    if (_controller.isConnected || _controller.state == LiveSessionState.connecting) {
      widget.onDisconnectPressed?.call();
      _controller.disconnect();
    } else {
      widget.onConnectPressed?.call();
      _connectSession();
    }
  }

  void _handleStopSpeaking() {
    widget.onStopSpeakingPressed?.call();
    _controller.stopModelSpeaking();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: widget.headerBuilder?.call(context, _controller) ?? _buildDefaultAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Live waveform header bar when connected
            if (widget.showWaveform && _controller.isConnected)
              _buildWaveformBar(context),

            // Transcript message list
            Expanded(
              child: _controller.transcripts.isEmpty
                  ? (widget.emptyBuilder?.call(context, _controller) ??
                      _buildDefaultEmpty(context))
                  : _buildMessageList(context),
            ),

            // Live streaming / speaking indicator
            if (widget.streamingIndicatorBuilder != null)
              widget.streamingIndicatorBuilder!(context, _controller.isModelSpeaking)
            else if (_controller.isModelSpeaking)
              _buildDefaultStreamingIndicator(context),

            // Chat input bar slot
            widget.inputBuilder?.call(
                  context,
                  _controller,
                  _textController,
                  _sendMessage,
                ) ??
                _buildDefaultInputBar(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(BuildContext context) {
    final isConnected = _controller.isConnected;
    final isConnecting = _controller.state == LiveSessionState.connecting;

    return AppBar(
      title: Text(widget.title),
      actions: [
        if (widget.showStatusBadge)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GeminiLiveStatusBadge(
              state: _mapSessionState(_controller.state),
            ),
          ),
        if (widget.showConnectionButton)
          IconButton(
            tooltip: isConnected || isConnecting
                ? 'Disconnect Gemini Live'
                : 'Connect Gemini Live',
            icon: Icon(
              isConnected || isConnecting
                  ? Icons.call_end_rounded
                  : Icons.phone_in_talk_rounded,
              color: isConnected || isConnecting
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
            onPressed: _handleToggleConnection,
          ),
        const SizedBox(width: 8.0),
      ],
    );
  }

  GeminiLiveSessionState _mapSessionState(LiveSessionState state) {
    switch (state) {
      case LiveSessionState.connected:
        return _controller.isModelSpeaking || _controller.isUserSpeaking
            ? GeminiLiveSessionState.inProgress
            : GeminiLiveSessionState.connected;
      case LiveSessionState.connecting:
        return GeminiLiveSessionState.connecting;
      case LiveSessionState.disconnecting:
      case LiveSessionState.disconnected:
      case LiveSessionState.error:
        return GeminiLiveSessionState.disconnected;
    }
  }

  Widget _buildWaveformBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
      child: Row(
        children: [
          Icon(
            _controller.isModelSpeaking ? Icons.volume_up_rounded : Icons.mic_rounded,
            size: 16.0,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8.0),
          Text(
            _controller.isModelSpeaking
                ? 'Gemini speaking...'
                : (_controller.isUserSpeaking ? 'Listening...' : 'Live session ready'),
            style: TextStyle(
              fontSize: 12.0,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GeminiLiveWaveform(
            audioStream: _controller.incomingAudioStream,
            barCount: 7,
            height: 18.0,
            barWidth: 3.0,
            spacing: 2.5,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.spatial_audio_rounded,
                size: 48.0,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Gemini Live Ready',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Speak into the microphone or type below to start the conversation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      itemCount: _controller.transcripts.length,
      itemBuilder: (context, index) {
        final item = _controller.transcripts[index];
        final isUser = item.role.toLowerCase() == 'user';

        // 1. Unified bubbleBuilder
        if (widget.bubbleBuilder != null) {
          return widget.bubbleBuilder!(context, item, isUser);
        }

        // 2. Specialized userBubbleBuilder
        if (isUser && widget.userBubbleBuilder != null) {
          return widget.userBubbleBuilder!(context, item, isUser);
        }

        // 3. Specialized modelBubbleBuilder
        if (!isUser && widget.modelBubbleBuilder != null) {
          return widget.modelBubbleBuilder!(context, item, isUser);
        }

        // 4. Default built-in Bubble
        return _buildDefaultBubble(context, item, isUser);
      },
    );
  }

  Widget _buildDefaultBubble(
    BuildContext context,
    LiveTranscriptItem item,
    bool isUser,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userBg = theme.colorScheme.primary;
    final userFg = theme.colorScheme.onPrimary;

    final modelBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final modelFg = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? userBg : modelBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
          ),
          border: !isUser
              ? Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (item.imageBytes != null && item.imageBytes!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.memory(
                  item.imageBytes!,
                  width: 180.0,
                  height: 140.0,
                  fit: BoxFit.cover,
                ),
              ),
              if (item.text.isNotEmpty) const SizedBox(height: 8.0),
            ],
            if (item.text.isNotEmpty)
              Text(
                item.text,
                style: TextStyle(
                  color: isUser ? userFg : modelFg,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            if (item.isStreaming) ...[
              const SizedBox(height: 4.0),
              SizedBox(
                width: 12.0,
                height: 12.0,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUser ? userFg.withValues(alpha: 0.7) : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultStreamingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 14.0,
            height: 14.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Gemini Live responding...',
              style: TextStyle(
                fontSize: 12.0,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: _handleStopSpeaking,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stop_circle_rounded,
                    size: 16.0,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Stop',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultInputBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached image thumbnail preview chip
          if (_attachedImageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      _attachedImageBytes!,
                      width: 64.0,
                      height: 64.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2.0,
                    right: 2.0,
                    child: GestureDetector(
                      onTap: clearAttachedImage,
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Push-to-Talk / Mic Button Toggle
              GeminiLiveMicButton(
                isRecording: _isRecordingMic,
                size: 42.0,
                iconSize: 20.0,
                onPressed: () {
                  setState(() {
                    _isRecordingMic = !_isRecordingMic;
                  });
                  if (!_isRecordingMic) {
                    _controller.stopUserSpeaking();
                  }
                },
              ),
              const SizedBox(width: 6.0),

              // Attachment action button (if onAttachPressed provided)
              if (widget.onAttachPressed != null) ...[
                IconButton(
                  tooltip: 'Attach Image / Photo',
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  onPressed: () => widget.onAttachPressed!(context, _controller),
                ),
                const SizedBox(width: 4.0),
              ],

              // Text Field
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: widget.inputHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Send Icon Button
              IconButton.filled(
                icon: const Icon(Icons.send_rounded, size: 18.0),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
