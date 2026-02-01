import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'main.dart';

/// A comprehensive demo page showcasing all new Gemini Live API features
class LiveAPIDemoPage extends StatefulWidget {
  const LiveAPIDemoPage({super.key});

  @override
  State<LiveAPIDemoPage> createState() => _LiveAPIDemoPageState();
}

class _LiveAPIDemoPageState extends State<LiveAPIDemoPage> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;

  // Message logs
  final List<LogEntry> _logs = [];

  // Feature toggles
  bool _enableRealtimeConfig = true;
  bool _enableTranscription = true;
  bool _enableSessionResumption = false;
  bool _enableContextCompression = true;
  bool _enableProactivity = true;

  // Session handle for resumption
  String? _sessionHandle;

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: geminiApiKey);
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }

  void _addLog(String type, String message, {Map<String, dynamic>? data}) {
    setState(() {
      _logs.insert(
        0,
        LogEntry(
          timestamp: DateTime.now(),
          type: type,
          message: message,
          data: data,
        ),
      );
    });
  }

  Future<void> _connect() async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);
    _addLog('SYSTEM', 'Connecting to Gemini Live API...');

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          config: GenerationConfig(
            temperature: 0.7,
            responseModalities: [Modality.TEXT, Modality.AUDIO],
          ),
          systemInstruction: Content(
            parts: [
              Part(
                text:
                    'You are a helpful AI assistant demonstrating advanced features.',
              ),
            ],
          ),
          // Realtime input configuration
          realtimeInputConfig: _enableRealtimeConfig
              ? RealtimeInputConfig(
                  automaticActivityDetection: AutomaticActivityDetection(
                    disabled: false,
                    startOfSpeechSensitivity:
                        StartSensitivity.START_SENSITIVITY_HIGH,
                    endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
                    prefixPaddingMs: 300,
                    silenceDurationMs: 500,
                  ),
                  activityHandling:
                      ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
                  turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
                )
              : null,
          // Audio transcription
          inputAudioTranscription: _enableTranscription
              ? AudioTranscriptionConfig()
              : null,
          outputAudioTranscription: _enableTranscription
              ? AudioTranscriptionConfig()
              : null,
          // Session resumption
          sessionResumption: _enableSessionResumption && _sessionHandle != null
              ? SessionResumptionConfig(
                  handle: _sessionHandle,
                  transparent: true,
                )
              : null,
          // Context window compression
          contextWindowCompression: _enableContextCompression
              ? ContextWindowCompressionConfig(
                  triggerTokens: '10000',
                  slidingWindow: SlidingWindow(targetTokens: '5000'),
                )
              : null,
          // Proactivity
          proactivity: _enableProactivity
              ? ProactivityConfig(proactiveAudio: true)
              : null,
          callbacks: LiveCallbacks(
            onOpen: () {
              _addLog('CONNECTION', '✅ Connected successfully');
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: _handleMessage,
            onError: (error, stack) {
              _addLog('ERROR', '❌ Error: $error');
              setState(() => _isConnecting = false);
            },
            onClose: (code, reason) {
              _addLog(
                'CONNECTION',
                '🔒 Connection closed: code=$code, reason=$reason',
              );
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
          ),
        ),
      );

      setState(() => _session = session);
    } catch (e) {
      _addLog('ERROR', '❌ Connection failed: $e');
      setState(() => _isConnecting = false);
    }
  }

  void _handleMessage(LiveServerMessage message) {
    // Handle text
    if (message.text != null) {
      _addLog('TEXT', '🤖 ${message.text}');
    }

    // Handle audio data
    if (message.data != null) {
      _addLog('AUDIO', '🔊 Received audio: ${message.data!.length} chars');
    }

    // Handle transcriptions
    if (message.serverContent?.inputTranscription != null) {
      final t = message.serverContent!.inputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        '🎤 Input: ${t.text} ${t.finished == true ? "(complete)" : ""}',
      );
    }

    if (message.serverContent?.outputTranscription != null) {
      final t = message.serverContent!.outputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        '🔈 Output: ${t.text} ${t.finished == true ? "(complete)" : ""}',
      );
    }

    // Handle voice activity
    if (message.voiceActivity != null) {
      _addLog(
        'VAD',
        '🎤 Voice activity: ${message.voiceActivity!.speechActive == true ? "speaking" : "silent"}',
      );
    }

    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) _addLog('VAD', '🎙️ Speech started');
      if (signal.end == true) _addLog('VAD', '🎙️ Speech ended');
    }

    // Handle session resumption
    if (message.sessionResumptionUpdate != null) {
      final update = message.sessionResumptionUpdate!;
      _addLog('SESSION', '🔄 Resumption update: handle=${update.newHandle}');
      if (update.newHandle != null) {
        setState(() => _sessionHandle = update.newHandle);
      }
    }

    // Handle go away
    if (message.goAway != null) {
      _addLog(
        'WARNING',
        '⏰ Server will disconnect in ${message.goAway!.timeRemaining}s: ${message.goAway!.reason}',
      );
    }

    // Handle usage
    if (message.usageMetadata != null) {
      final u = message.usageMetadata!;
      _addLog(
        'USAGE',
        '📊 Tokens: ${u.totalTokenCount} (prompt: ${u.promptTokenCount}, response: ${u.responseTokenCount})',
      );
    }
  }

  void _sendText(String text) {
    if (_session == null || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '💬 $text');
    _session!.sendText(text);
  }

  void _sendClientContent() {
    if (_session == null || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '💬 [Multi-turn content]');
    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: [Part(text: 'Remember: my favorite color is blue.')],
        ),
        Content(
          role: 'model',
          parts: [
            Part(text: 'I\'ll remember that your favorite color is blue.'),
          ],
        ),
        Content(
          role: 'user',
          parts: [Part(text: 'What\'s my favorite color?')],
        ),
      ],
      turnComplete: true,
    );
  }

  void _sendRealtimeInput() {
    if (_session == null || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '🎙️ [Realtime input with media]');
    _session!.sendRealtimeInput(
      text: 'This is realtime text input',
      audioStreamEnd: true,
    );
  }

  void _toggleActivity(bool isStart) {
    if (_session == null || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    if (isStart) {
      _addLog('USER', '🎙️ [Activity Start]');
      _session!.sendActivityStart();
    } else {
      _addLog('USER', '🎙️ [Activity End]');
      _session!.sendActivityEnd();
    }
  }

  void _closeConnection() {
    _session?.close();
    _addLog('SYSTEM', '👋 Closing connection...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live API Features Demo'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeConnection,
              tooltip: 'Close connection',
            ),
        ],
      ),
      body: Column(
        children: [
          // Feature toggles
          _buildFeatureToggles(),
          const Divider(),
          // Connection button
          _buildConnectionButton(),
          const Divider(),
          // Action buttons
          if (_isConnected) _buildActionButtons(),
          const Divider(),
          // Logs
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildFeatureToggles() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildToggle(
            'Realtime Config',
            _enableRealtimeConfig,
            (v) => setState(() => _enableRealtimeConfig = v),
          ),
          _buildToggle(
            'Transcription',
            _enableTranscription,
            (v) => setState(() => _enableTranscription = v),
          ),
          _buildToggle(
            'Session Resume',
            _enableSessionResumption,
            (v) => setState(() => _enableSessionResumption = v),
          ),
          _buildToggle(
            'Context Compression',
            _enableContextCompression,
            (v) => setState(() => _enableContextCompression = v),
          ),
          _buildToggle(
            'Proactivity',
            _enableProactivity,
            (v) => setState(() => _enableProactivity = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: _isConnected ? null : onChanged,
    );
  }

  Widget _buildConnectionButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _isConnected ? null : _connect,
        icon: _isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isConnected
                    ? Icons.check_circle
                    : Icons.connect_without_contact,
              ),
        label: Text(
          _isConnecting
              ? 'Connecting...'
              : _isConnected
              ? 'Connected'
              : 'Connect to Live API',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConnected ? Colors.green : null,
          foregroundColor: _isConnected ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () => _showTextInputDialog(),
              child: const Text('Send Text'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendClientContent,
              child: const Text('Multi-turn'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendRealtimeInput,
              child: const Text('Realtime Input'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _toggleActivity(true),
              child: const Text('Activity Start'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _toggleActivity(false),
              child: const Text('Activity End'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your message'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _sendText(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return ListTile(
          dense: true,
          leading: _buildLogIcon(log.type),
          title: Text(
            log.message,
            style: TextStyle(fontSize: 13, color: _getLogColor(log.type)),
          ),
          subtitle: Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildLogIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'TEXT':
        icon = Icons.chat_bubble;
        color = Colors.blue;
        break;
      case 'AUDIO':
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case 'TRANSCRIPTION':
        icon = Icons.transcribe;
        color = Colors.teal;
        break;
      case 'VAD':
        icon = Icons.mic;
        color = Colors.orange;
        break;
      case 'SESSION':
        icon = Icons.sync;
        color = Colors.indigo;
        break;
      case 'USAGE':
        icon = Icons.analytics;
        color = Colors.grey;
        break;
      case 'ERROR':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'WARNING':
        icon = Icons.warning;
        color = Colors.amber;
        break;
      case 'CONNECTION':
        icon = Icons.link;
        color = Colors.green;
        break;
      case 'SYSTEM':
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.amber.shade800;
      case 'TEXT':
        return Colors.blue.shade800;
      default:
        return Colors.black87;
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final String type;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.data,
  });
}
