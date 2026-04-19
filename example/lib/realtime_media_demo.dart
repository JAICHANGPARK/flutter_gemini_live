import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:gemini_live/gemini_live.dart';

import 'api_key_store.dart';
import 'live_audio_player.dart';
import 'live_api_defaults.dart';

/// Demo page for realtime audio/video input features.
class RealtimeMediaDemoPage extends StatefulWidget {
  const RealtimeMediaDemoPage({super.key});

  @override
  State<RealtimeMediaDemoPage> createState() => _RealtimeMediaDemoPageState();
}

class _RealtimeMediaDemoPageState extends State<RealtimeMediaDemoPage>
    with WidgetsBindingObserver {
  static const _cameraFrameInterval = Duration(milliseconds: 1200);
  static const _audioSampleRate = 16000;
  static const _audioMimeType = 'audio/pcm;rate=16000';

  late final GoogleGenAI _genAI;
  final LiveAudioPlayer _responseAudioPlayer = LiveAudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _picker = ImagePicker();

  LiveSession? _session;
  CameraController? _cameraController;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSendingVideo = false;
  bool _isCameraInitializing = false;
  bool _isStreamingAudio = false;
  bool _isStreamingCamera = false;
  bool _captureInFlight = false;

  final List<MediaLog> _logs = [];
  final List<CameraDescription> _availableCameras = [];

  // Activity detection mode
  bool _manualActivityMode = false;
  bool _isActivityActive = false;
  bool _isAutomaticSpeechActive = false;

  int _selectedCameraIndex = 0;
  int _audioChunksSent = 0;
  int _videoFramesSent = 0;

  bool get _cameraReady => _cameraController?.value.isInitialized ?? false;
  bool get _cameraInputActive =>
      _manualActivityMode ? _isActivityActive : _isAutomaticSpeechActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
    unawaited(_loadAvailableCameras());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    unawaited(_audioRecorder.stop());
    unawaited(_audioRecorder.dispose());
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    _session?.close();
    unawaited(_responseAudioPlayer.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraFrameTimer?.cancel();
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {
          _cameraController = null;
          _isStreamingCamera = false;
        });
      }
    } else if (state == AppLifecycleState.resumed &&
        _availableCameras.isNotEmpty) {
      unawaited(
        _initializeCameraController(
          _availableCameras[_selectedCameraIndex],
          logStatus: false,
        ),
      );
    }
  }

  void _addLog(String type, String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(
        0,
        MediaLog(timestamp: DateTime.now(), type: type, message: message),
      );
    });
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      setState(() {
        _availableCameras
          ..clear()
          ..addAll(cameras);
        if (_selectedCameraIndex >= _availableCameras.length) {
          _selectedCameraIndex = 0;
        }
      });

      if (cameras.isEmpty) {
        _addLog('VIDEO', '⚠️ No camera devices were found on this platform.');
        return;
      }

      await _initializeCameraController(
        _availableCameras[_selectedCameraIndex],
        logStatus: false,
      );
    } on CameraException catch (error) {
      _addLog(
        'ERROR',
        '❌ Camera is unavailable: ${_describeCameraError(error)}',
      );
    } catch (error) {
      _addLog('ERROR', '❌ Camera is unavailable: $error');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription description, {
    bool logStatus = true,
  }) async {
    if (_isCameraInitializing) return;

    setState(() => _isCameraInitializing = true);

    final previousController = _cameraController;

    try {
      await previousController?.dispose();

      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Flash mode may be unsupported on some cameras.
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
      });

      if (logStatus) {
        _addLog('VIDEO', '✅ Camera ready: ${_cameraLabel(description)}');
      }
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _isCameraInitializing = false;
      });
      _addLog('ERROR', '❌ Camera init failed: ${_describeCameraError(error)}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _isCameraInitializing = false;
      });
      _addLog('ERROR', '❌ Camera init failed: $error');
    }
  }

  String _cameraLabel(CameraDescription description) {
    if (description.name.isNotEmpty) {
      return description.name;
    }
    return description.lensDirection.name;
  }

  String _describeCameraError(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'camera permission was denied';
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        return 'microphone permission was denied by the camera plugin';
      default:
        return '${error.code}: ${error.description ?? 'unknown camera error'}';
    }
  }

  Future<bool> _ensureCameraReady() async {
    if (_cameraReady) return true;

    if (_availableCameras.isEmpty) {
      await _loadAvailableCameras();
    }

    if (_availableCameras.isEmpty) {
      _addLog(
        'ERROR',
        '❌ Camera preview is unavailable. Check camera access and whether a camera device is attached.',
      );
      return false;
    }

    await _initializeCameraController(_availableCameras[_selectedCameraIndex]);
    return _cameraReady;
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCameraInitializing) return;

    final shouldResumeFrames = _isStreamingCamera;
    _cameraFrameTimer?.cancel();

    setState(() {
      _selectedCameraIndex =
          (_selectedCameraIndex + 1) % _availableCameras.length;
      _isStreamingCamera = false;
    });

    await _initializeCameraController(_availableCameras[_selectedCameraIndex]);

    if (shouldResumeFrames && _cameraReady) {
      _startCameraFrameLoop();
    }
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _addLog('ERROR', '❌ API key is not configured. Open Settings first.');
      return;
    }

    setState(() => _isConnecting = true);
    _addLog('SYSTEM', 'Connecting to Live API with Gemini 3.1 Flash Live...');
    await _responseAudioPlayer.stop();

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: kLatestRealtimeLiveModel,
          config: buildExampleAudioGenerationConfig(temperature: 0.7),
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
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              _addLog('CONNECTION', '✅ Connected');
              if (!mounted) return;
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: _handleMessage,
            onError: (error, stack) {
              unawaited(_stopLiveMultimodalStream(sendAudioStreamEnd: false));
              unawaited(_responseAudioPlayer.stop());
              _addLog('ERROR', '❌ $error');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
            onClose: (code, reason) {
              unawaited(_stopLiveMultimodalStream(sendAudioStreamEnd: false));
              unawaited(_responseAudioPlayer.stop());
              _addLog('CONNECTION', '🔒 Disconnected');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
          ),
        ),
      );

      if (!mounted) return;
      setState(() => _session = session);
    } catch (error) {
      _addLog('ERROR', '❌ Connection failed: $error');
      if (!mounted) return;
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _stopLiveMultimodalStream();
    await _responseAudioPlayer.stop();
    await _session?.close();
    if (!mounted) return;
    setState(() {
      _session = null;
      _isConnected = false;
      _isConnecting = false;
    });
  }

  void _handleMessage(LiveServerMessage message) {
    final serverContent = message.serverContent;
    final turnFinished =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (serverContent?.interrupted ?? false) {
      _responseAudioPlayer.clear();
    }

    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      _addLog('TEXT', '🤖 $textChunk');
    }

    if (message.data != null) {
      _responseAudioPlayer.appendBase64Chunk(message.data!);
      _addLog('AUDIO', '🔊 Received audio: ${message.data!.length} chars');
    }

    if (message.serverContent?.inputTranscription != null) {
      final transcription = message.serverContent!.inputTranscription!;
      _addLog('TRANSCRIPTION', '🎤 Input: ${transcription.text}');
    }
    if (message.serverContent?.outputTranscription != null) {
      final transcription = message.serverContent!.outputTranscription!;
      _addLog('TRANSCRIPTION', '🔈 Output: ${transcription.text}');
    }

    if (message.voiceActivity != null) {
      if (!_manualActivityMode && mounted) {
        setState(
          () => _isAutomaticSpeechActive =
              message.voiceActivity!.speechActive == true,
        );
      }
      _addLog(
        'VAD',
        '🎤 ${message.voiceActivity!.speechActive == true ? "Speaking" : "Silent"}',
      );
    }
    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) {
        _addLog('VAD', '🎙️ Speech started');
        if (!_manualActivityMode) {
          if (mounted) {
            setState(() => _isAutomaticSpeechActive = true);
          } else {
            _isAutomaticSpeechActive = true;
          }
          if (_isStreamingAudio && !_isStreamingCamera) {
            _startCameraFrameLoop(logStart: true);
          }
        }
      }
      if (signal.end == true) {
        _addLog('VAD', '🎙️ Speech ended');
        if (!_manualActivityMode) {
          if (mounted) {
            setState(() => _isAutomaticSpeechActive = false);
          } else {
            _isAutomaticSpeechActive = false;
          }
          _stopCameraFrameLoop(logStop: true);
        }
      }
    }

    if (turnFinished && _responseAudioPlayer.hasBufferedAudio) {
      _addLog('AUDIO', '▶️ Playing received audio');
      unawaited(_responseAudioPlayer.playBufferedAudio());
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
      if (_isStreamingAudio) {
        _startCameraFrameLoop(logStart: true);
      }
    } else {
      _addLog('ACTIVITY', '🎙️ Activity END');
      _session!.sendActivityEnd();
      _stopCameraFrameLoop(logStop: true);
    }
  }

  void _sendAudioStreamEnd() {
    if (_session == null || !_isConnected) return;
    _addLog('AUDIO', '🔇 Audio stream end signal');
    _session!.sendAudioStreamEnd();
  }

  Future<void> _pickAndSendImage() async {
    if (_session == null || !_isConnected) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isSendingVideo = true);
    _addLog('VIDEO', '📷 Sending image...');

    try {
      final bytes = await image.readAsBytes();
      _session!.sendVideo(bytes);
      _addLog('VIDEO', '✅ Image sent: ${bytes.length} bytes');
    } catch (error) {
      _addLog('ERROR', '❌ Failed to send image: $error');
    }

    if (mounted) {
      setState(() => _isSendingVideo = false);
    }
  }

  Future<void> _sendMediaChunks() async {
    if (_session == null || !_isConnected) return;

    _addLog('MEDIA', '📦 Sending media chunks...');

    final chunks = [
      Blob(mimeType: 'audio/pcm', data: base64Encode([1, 2, 3, 4, 5])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([6, 7, 8, 9, 10])),
      Blob(mimeType: 'audio/pcm', data: base64Encode([11, 12, 13, 14, 15])),
    ];

    _session!.sendMediaChunks(chunks);
    _addLog('MEDIA', '✅ Sent ${chunks.length} chunks');
  }

  Future<void> _sendCombinedRealtimeInput() async {
    if (_session == null || !_isConnected) return;

    final cameraReady = await _ensureCameraReady();
    if (!cameraReady) return;

    await _captureAndSendCameraFrame(logUpload: true);
    _session!.sendRealtimeText(
      'Describe what you see in the current camera frame.',
    );
    _addLog('USER', '🔄 Sent current camera frame with a prompt');
  }

  Future<void> _startLiveMultimodalStream() async {
    if (_session == null || !_isConnected) {
      _addLog('ERROR', '❌ Connect to the Live session first.');
      return;
    }
    if (_isStreamingAudio || _isStreamingCamera) return;

    final hasMicPermission = await _audioRecorder.hasPermission();
    if (!hasMicPermission) {
      _addLog('ERROR', '❌ Microphone permission is required.');
      return;
    }

    final cameraReady = await _ensureCameraReady();
    if (!cameraReady) return;

    try {
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _audioSampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
          streamBufferSize: 2048,
        ),
      );

      await _audioStreamSubscription?.cancel();
      _audioChunksSent = 0;
      _videoFramesSent = 0;

      _audioStreamSubscription = stream.listen(
        (chunk) {
          if (_session == null || !_isConnected) return;

          _audioChunksSent += 1;
          _session!.sendRealtimeInput(
            audio: Blob(mimeType: _audioMimeType, data: base64Encode(chunk)),
          );

          if (mounted && _audioChunksSent % 12 == 0) {
            setState(() {});
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _addLog('ERROR', '❌ Audio stream failed: $error');
          unawaited(_stopLiveMultimodalStream(sendAudioStreamEnd: false));
        },
        cancelOnError: true,
      );

      if (_manualActivityMode && !_isActivityActive) {
        _session!.sendActivityStart();
        _addLog('ACTIVITY', '🎙️ Activity START (live camera + voice)');
        _isActivityActive = true;
      }

      if (!mounted) return;
      setState(() {
        _isStreamingAudio = true;
        _isStreamingCamera = _manualActivityMode;
      });

      _addLog('AUDIO', '🎤 Microphone streaming started (16 kHz PCM)');
      if (_manualActivityMode) {
        _addLog(
          'VIDEO',
          '📹 Camera frame streaming started (${_cameraFrameInterval.inMilliseconds} ms snapshots)',
        );
        _startCameraFrameLoop();
      } else {
        _addLog(
          'VIDEO',
          '📹 Auto mode is armed. Camera frames upload only while speech is detected.',
        );
      }
    } catch (error) {
      _addLog('ERROR', '❌ Failed to start live camera + voice stream: $error');
    }
  }

  void _startCameraFrameLoop({bool logStart = false}) {
    if (_cameraFrameTimer != null) return;
    if (mounted) {
      setState(() => _isStreamingCamera = true);
    } else {
      _isStreamingCamera = true;
    }

    if (logStart) {
      _addLog(
        'VIDEO',
        '📹 Camera frame streaming started (${_cameraFrameInterval.inMilliseconds} ms snapshots)',
      );
    }

    unawaited(_captureAndSendCameraFrame(logUpload: true));
    _cameraFrameTimer = Timer.periodic(
      _cameraFrameInterval,
      (_) => unawaited(_captureAndSendCameraFrame()),
    );
  }

  void _stopCameraFrameLoop({bool logStop = false}) {
    final wasStreaming = _cameraFrameTimer != null || _isStreamingCamera;
    _cameraFrameTimer?.cancel();
    _cameraFrameTimer = null;

    if (mounted) {
      setState(() => _isStreamingCamera = false);
    } else {
      _isStreamingCamera = false;
    }

    if (logStop && wasStreaming) {
      _addLog('VIDEO', '⏹️ Camera frame streaming stopped');
    }
  }

  Future<void> _captureAndSendCameraFrame({bool logUpload = false}) async {
    final controller = _cameraController;
    if (_captureInFlight ||
        controller == null ||
        !controller.value.isInitialized ||
        _session == null ||
        !_isConnected) {
      return;
    }

    _captureInFlight = true;

    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();

      _session!.sendRealtimeInput(
        video: Blob(mimeType: 'image/jpeg', data: base64Encode(bytes)),
      );

      _videoFramesSent += 1;

      if (logUpload || _videoFramesSent % 5 == 0) {
        _addLog(
          'VIDEO',
          '📸 Sent live camera frame #$_videoFramesSent (${bytes.length} bytes)',
        );
      } else if (mounted) {
        setState(() {});
      }
    } catch (error) {
      _addLog('ERROR', '❌ Camera frame upload failed: $error');
    } finally {
      _captureInFlight = false;
    }
  }

  Future<void> _stopLiveMultimodalStream({
    bool sendAudioStreamEnd = true,
  }) async {
    final wasStreamingAudio = _isStreamingAudio;
    final wasStreamingCamera = _isStreamingCamera;

    _stopCameraFrameLoop();

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    if (wasStreamingAudio) {
      if (sendAudioStreamEnd && _session != null && _isConnected) {
        _session!.sendAudioStreamEnd();
      }

      try {
        await _audioRecorder.stop();
      } catch (_) {
        // Ignore recorder shutdown errors during teardown.
      }
    }

    if (_manualActivityMode &&
        _isActivityActive &&
        _session != null &&
        _isConnected) {
      _session!.sendActivityEnd();
      _addLog('ACTIVITY', '🎙️ Activity END (live camera + voice)');
      _isActivityActive = false;
    }

    _isAutomaticSpeechActive = false;

    if (!mounted) return;
    setState(() {
      _isStreamingAudio = false;
      _captureInFlight = false;
    });

    if (wasStreamingAudio) {
      _addLog('AUDIO', '⏹️ Microphone streaming stopped');
    }
    if (wasStreamingCamera) {
      _addLog('VIDEO', '⏹️ Camera frame streaming stopped');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Media Demo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;
          final compact =
              constraints.maxHeight < 760 || constraints.maxWidth < 900;

          if (isWide) {
            final controlsWidth = (constraints.maxWidth * 0.42)
                .clamp(360.0, 520.0)
                .toDouble();

            return Row(
              children: [
                SizedBox(
                  width: controlsWidth,
                  child: SingleChildScrollView(
                    child: _buildControlPanel(compact: compact),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildLogSection()),
              ],
            );
          }

          final logHeight = (constraints.maxHeight * 0.34)
              .clamp(180.0, 300.0)
              .toDouble();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildControlPanel(compact: compact),
                ),
              ),
              _buildSectionDivider(),
              Expanded(
                child: SizedBox(height: logHeight, child: _buildLogSection()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlPanel({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModeSelection(),
        _buildSectionDivider(),
        _buildConnectionButton(),
        if (_isConnected) ...[
          _buildSectionDivider(),
          _buildMediaControls(compact: compact),
        ],
      ],
    );
  }

  Widget _buildSectionDivider() {
    return const Divider(height: 1);
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
                : (selected) {
                    setState(() => _manualActivityMode = selected.first);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            _manualActivityMode
                ? 'Manual mode: live camera + voice starts an activity automatically, and you can still end it yourself.'
                : 'Auto mode: microphone audio streams continuously, and camera frames upload only while speech is detected.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
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
          OutlinedButton.icon(
            onPressed: _isConnected ? _disconnect : null,
            icon: const Icon(Icons.link_off),
            label: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControls({required bool compact}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildCameraVoiceCard(compact: compact),
          const SizedBox(height: 12),
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
                label: const Text('Frame + Prompt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraVoiceCard({required bool compact}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final previewHeight = compact
                ? (maxWidth * 0.5).clamp(180.0, 240.0).toDouble()
                : (maxWidth / (4 / 3)).clamp(220.0, 360.0).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.podcasts),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live Camera + Voice',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(
                        _isStreamingAudio
                            ? _cameraInputActive
                                  ? 'Audio + Video'
                                  : 'Audio Only'
                            : 'Idle',
                      ),
                      backgroundColor: (_isStreamingAudio || _isStreamingCamera)
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _manualActivityMode
                      ? 'This example keeps a live camera preview on screen, uploads a JPEG snapshot every 1.2 seconds while the activity is active, and streams microphone PCM chunks to the same Live session.'
                      : 'This example keeps a live camera preview on screen, streams microphone PCM chunks continuously, and uploads JPEG snapshots only while speech is being detected.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: previewHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildCameraPreview(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isCameraInitializing
                          ? null
                          : () => _ensureCameraReady(),
                      icon: _isCameraInitializing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.videocam),
                      label: Text(
                        _cameraReady ? 'Refresh Camera' : 'Initialize Camera',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _availableCameras.length > 1
                          ? _switchCamera
                          : null,
                      icon: const Icon(Icons.cameraswitch),
                      label: const Text('Switch Camera'),
                    ),
                    FilledButton.icon(
                      onPressed: (!_isConnected || _isStreamingAudio)
                          ? null
                          : _startLiveMultimodalStream,
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text('Start Camera + Voice'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_isStreamingAudio || _isStreamingCamera)
                          ? _stopLiveMultimodalStream
                          : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop Stream'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      Icons.mic,
                      _isStreamingAudio ? 'Mic on' : 'Mic idle',
                    ),
                    _buildStatChip(Icons.image, 'Frames $_videoFramesSent'),
                    _buildStatChip(
                      Icons.graphic_eq,
                      'Audio chunks $_audioChunksSent',
                    ),
                    if (_availableCameras.isNotEmpty)
                      _buildStatChip(
                        Icons.camera_front,
                        _cameraLabel(_availableCameras[_selectedCameraIndex]),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  _cameraLabel(controller.description),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final hasKnownCameraDevices = _availableCameras.isNotEmpty;
    final message = hasKnownCameraDevices
        ? 'Camera preview is not ready yet. Tap Initialize Camera.'
        : 'Camera preview is unavailable on this device, permission has not been granted, or no camera is attached.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 40, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
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

  Widget _buildLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Live Logs',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Chip(
                label: Text('${_logs.length} entries'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        _buildSectionDivider(),
        Expanded(child: _buildLogList()),
      ],
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
