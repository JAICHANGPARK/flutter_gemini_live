import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';

/// Demo page for realtime audio/video input features
class RealtimeMediaDemoPage extends StatefulWidget {
  const RealtimeMediaDemoPage({super.key});

  @override
  State<RealtimeMediaDemoPage> createState() => _RealtimeMediaDemoPageState();
}

class _RealtimeMediaDemoPageState extends State<RealtimeMediaDemoPage> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSendingVideo = false;

  final List<MediaLog> _logs = [];
  final ImagePicker _picker = ImagePicker();

  // Activity detection mode
  bool _manualActivityMode = false;
  bool _isActivityActive = false;

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }

  void _addLog(String type, String message) {
    setState(() {
      _logs.insert(
        0,
        MediaLog(timestamp: DateTime.now(), type: type, message: message),
      );
    });
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _addLog('ERROR', '❌ API key is not configured. Open Settings first.');
      return;
    }

    setState(() => _isConnecting = true);
    _addLog('SYSTEM', 'Connecting to Live API...');

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-live-2.5-flash-preview',
          config: GenerationConfig(
            temperature: 0.7,
            responseModalities: [Modality.TEXT],
          ),
          // Configure based on manual activity mode
          realtimeInputConfig: _manualActivityMode
              ? RealtimeInputConfig(
                  automaticActivityDetection: AutomaticActivityDetection(
                    disabled: true,
                  ),
                )
              : RealtimeInputConfig(
                  automaticActivityDetection: AutomaticActivityDetection(
                    disabled: false,
                    startOfSpeechSensitivity:
                        StartSensitivity.START_SENSITIVITY_HIGH,
                    endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
                    prefixPaddingMs: 300,
                    silenceDurationMs: 500,
                  ),
                ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              _addLog('CONNECTION', '✅ Connected');
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: _handleMessage,
            onError: (error, stack) {
              _addLog('ERROR', '❌ $error');
              setState(() => _isConnecting = false);
            },
            onClose: (code, reason) {
              _addLog('CONNECTION', '🔒 Disconnected');
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
    // Text response
    if (message.text != null) {
      _addLog('TEXT', '🤖 ${message.text}');
    }

    // Transcriptions
    if (message.serverContent?.inputTranscription != null) {
      final t = message.serverContent!.inputTranscription!;
      _addLog('TRANSCRIPTION', '🎤 Input: ${t.text}');
    }
    if (message.serverContent?.outputTranscription != null) {
      final t = message.serverContent!.outputTranscription!;
      _addLog('TRANSCRIPTION', '🔈 Output: ${t.text}');
    }

    // Voice activity
    if (message.voiceActivity != null) {
      _addLog(
        'VAD',
        '🎤 ${message.voiceActivity!.speechActive == true ? "Speaking" : "Silent"}',
      );
    }
    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) _addLog('VAD', '🎙️ Speech started');
      if (signal.end == true) _addLog('VAD', '🎙️ Speech ended');
    }
  }

  void _sendRealtimeText(String text) {
    if (_session == null || !_isConnected) return;
    _addLog('USER', '💬 Realtime text: $text');
    _session!.sendRealtimeText(text);
  }

  void _toggleActivity() {
    if (_session == null || !_isConnected) return;

    setState(() => _isActivityActive = !_isActivityActive);

    if (_isActivityActive) {
      _addLog('ACTIVITY', '🎙️ Activity START');
      _session!.sendActivityStart();
    } else {
      _addLog('ACTIVITY', '🎙️ Activity END');
      _session!.sendActivityEnd();
    }
  }

  void _sendAudioStreamEnd() {
    if (_session == null || !_isConnected) return;
    _addLog('AUDIO', '🔇 Audio stream end signal');
    _session!.sendAudioStreamEnd();
  }

  Future<void> _pickAndSendImage() async {
    if (_session == null || !_isConnected) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _isSendingVideo = true);
      _addLog('VIDEO', '📷 Sending image...');

      try {
        final bytes = await image.readAsBytes();
        _session!.sendVideo(bytes);
        _addLog('VIDEO', '✅ Image sent: ${bytes.length} bytes');
      } catch (e) {
        _addLog('ERROR', '❌ Failed to send image: $e');
      }

      setState(() => _isSendingVideo = false);
    }
  }

  Future<void> _sendMediaChunks() async {
    if (_session == null || !_isConnected) return;

    _addLog('MEDIA', '📦 Sending media chunks...');

    // Simulate sending multiple media chunks
    final chunks = [
      Blob(mimeType: 'audio/pcm', data: base64Encode([1, 2, 3, 4, 5])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([6, 7, 8, 9, 10])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([11, 12, 13, 14, 15])),
    ];

    _session!.sendMediaChunks(chunks);
    _addLog('MEDIA', '✅ Sent ${chunks.length} chunks');
  }

  void _sendCombinedRealtimeInput() {
    if (_session == null || !_isConnected) return;

    _addLog('USER', '🔄 Combined realtime input');

    // Simulate audio data
    final random = Random();
    final audioBytes = List<int>.generate(100, (_) => random.nextInt(256));

    _session!.sendRealtimeInput(
      audio: Blob(mimeType: 'audio/pcm', data: base64Encode(audioBytes)),
      text: 'Realtime text accompanying audio',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Media Demo'),
        actions: [
          // Activity detection mode toggle
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_manualActivityMode ? 'Manual VAD' : 'Auto VAD'),
                selected: _manualActivityMode,
                onSelected: (_) {},
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode selection
          _buildModeSelection(),
          const Divider(),

          // Connection button
          _buildConnectionButton(),
          const Divider(),

          // Media controls
          if (_isConnected) _buildMediaControls(),
          const Divider(),

          // Logs
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Detection Mode:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Automatic'),
                icon: Icon(Icons.auto_mode),
              ),
              ButtonSegment(
                value: true,
                label: Text('Manual'),
                icon: Icon(Icons.touch_app),
              ),
            ],
            selected: {_manualActivityMode},
            onSelectionChanged: _isConnected
                ? null
                : (Set<bool> selected) {
                    setState(() => _manualActivityMode = selected.first);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            _manualActivityMode
                ? 'Manual mode: You control when activity starts/ends'
                : 'Auto mode: Server detects speech automatically',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              : 'Connect',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConnected ? Colors.green : null,
          foregroundColor: _isConnected ? Colors.white : null,
          minimumSize: const Size(200, 48),
        ),
      ),
    );
  }

  Widget _buildMediaControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Realtime text input
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Send realtime text...',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _sendRealtimeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Activity controls (manual mode)
          if (_manualActivityMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleActivity,
                  icon: Icon(_isActivityActive ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isActivityActive ? 'End Activity' : 'Start Activity',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActivityActive
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

          if (_manualActivityMode) const SizedBox(height: 12),

          // Media buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _sendAudioStreamEnd,
                icon: const Icon(Icons.stop_circle),
                label: const Text('Audio End'),
              ),
              ElevatedButton.icon(
                onPressed: _isSendingVideo ? null : _pickAndSendImage,
                icon: _isSendingVideo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image),
                label: const Text('Send Image'),
              ),
              ElevatedButton.icon(
                onPressed: _sendMediaChunks,
                icon: const Icon(Icons.folder_zip),
                label: const Text('Media Chunks'),
              ),
              ElevatedButton.icon(
                onPressed: _sendCombinedRealtimeInput,
                icon: const Icon(Icons.merge_type),
                label: const Text('Combined'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: _getLogColor(log.type),
          child: ListTile(
            dense: true,
            leading: Icon(_getLogIcon(log.type), size: 20),
            title: Text(log.message, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'TEXT':
        return Icons.chat;
      case 'TRANSCRIPTION':
        return Icons.transcribe;
      case 'VAD':
        return Icons.mic;
      case 'VIDEO':
        return Icons.video_call;
      case 'MEDIA':
        return Icons.perm_media;
      case 'ACTIVITY':
        return Icons.touch_app;
      case 'AUDIO':
        return Icons.audiotrack;
      case 'ERROR':
        return Icons.error;
      case 'CONNECTION':
        return Icons.link;
      default:
        return Icons.info;
    }
  }

  Color? _getLogColor(String type) {
    switch (type) {
      case 'TEXT':
        return Colors.blue.shade50;
      case 'TRANSCRIPTION':
        return Colors.teal.shade50;
      case 'VAD':
        return Colors.orange.shade50;
      case 'VIDEO':
        return Colors.purple.shade50;
      case 'ACTIVITY':
        return Colors.green.shade50;
      case 'ERROR':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
}

class MediaLog {
  final DateTime timestamp;
  final String type;
  final String message;

  MediaLog({
    required this.timestamp,
    required this.type,
    required this.message,
  });
}
