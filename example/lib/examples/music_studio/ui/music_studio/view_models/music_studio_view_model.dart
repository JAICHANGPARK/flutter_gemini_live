import 'dart:async';
import 'dart:math' as math;

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
// TextEditingController is a plain ChangeNotifier the prompt rows bind to; the
// view model owns it so the prompt text / weight lists stay index-aligned.
import 'package:flutter/widgets.dart' show TextEditingController;
import 'package:gemini_live/gemini_live.dart';

import '../../../data/repositories/music_log_repository.dart';
import '../../../data/services/music_studio_audio_service.dart';
import '../../../data/services/music_studio_live_service.dart';
import '../../../domain/models/music_preset.dart';
import '../../../domain/models/music_studio_status.dart';
import '../../../domain/music_presets.dart';
import 'music_studio_notice.dart';

/// State + logic for the Live Music Studio (Lyria Live) screen.
///
/// Coarse state notifies through [ChangeNotifier]. The visualizer bars are
/// animated at frame rate and notify through [visualizerTick] only.
///
/// The view model never touches a `BuildContext`; it asks the view for things
/// via [onNotice], [requestApiKeySetup], [onVisualizerStart] and
/// [onVisualizerStop].
class MusicStudioViewModel extends ChangeNotifier {
  MusicStudioViewModel({
    MusicStudioAudioService? audioService,
    MusicStudioLiveService? liveService,
    MusicLogRepository? logRepository,
  }) : _audio = audioService ?? MusicStudioAudioService(),
       _live = liveService ?? MusicStudioLiveService(),
       _logRepo = logRepository ?? MusicLogRepository();

  final MusicStudioAudioService _audio;
  final MusicStudioLiveService _live;
  final MusicLogRepository _logRepo;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(MusicStudioNotice notice)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  /// Start the (repeating, reversing) visualizer animation.
  VoidCallback? onVisualizerStart;

  /// Stop the visualizer animation.
  VoidCallback? onVisualizerStop;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // Session
  LiveMusicSession? _session;

  // Connection & Playback State
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;
  MusicStudioStatus _status = MusicStudioStatus.disconnected;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isPlaying => _isPlaying;
  MusicStudioStatus get status => _status;

  // Selected Model
  String _selectedModel = LiveMusicModels.lyriaRealtimeExp;
  String get selectedModel => _selectedModel;

  // Stream Metrics
  int _receivedChunksCount = 0;
  int _totalBytesReceived = 0;
  int get receivedChunksCount => _receivedChunksCount;
  int get totalBytesReceived => _totalBytesReceived;
  List<String> get logs => _logRepo.logs;

  // Weighted Prompts
  final List<TextEditingController> _promptControllers = [];
  final List<double> _promptWeights = [];
  List<TextEditingController> get promptControllers => _promptControllers;
  List<double> get promptWeights => _promptWeights;

  // Generation Config State
  int _bpm = 120;
  int? _lastAppliedBpm;
  Scale? _selectedScale;
  Scale? _lastAppliedScale;
  bool _autoResetOnTempoScaleChange = true;
  MusicGenerationMode _mode = MusicGenerationMode.QUALITY;
  double _temperature = 1.1; // Official Lyria default
  double _guidance = 4.0; // Official Lyria default
  double _density = 0.5;
  double _brightness = 0.5;
  bool _muteBass = false;
  bool _muteDrums = false;
  bool _onlyBassAndDrums = false;

  int get bpm => _bpm;
  Scale? get selectedScale => _selectedScale;
  bool get autoResetOnTempoScaleChange => _autoResetOnTempoScaleChange;
  MusicGenerationMode get mode => _mode;
  double get temperature => _temperature;
  double get guidance => _guidance;
  double get density => _density;
  double get brightness => _brightness;
  bool get muteBass => _muteBass;
  bool get muteDrums => _muteDrums;
  bool get onlyBassAndDrums => _onlyBassAndDrums;

  // Prompt DJ Crossfader value [0.0 = Prompt A 100%, 1.0 = Prompt B 100%]
  double _crossfaderValue = 0.5;
  double get crossfaderValue => _crossfaderValue;

  // Visualizer
  final List<double> visualizerBars = List.generate(24, (index) => 0.1);
  final ValueNotifier<int> visualizerTick = ValueNotifier<int>(0);

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  void init() {
    _audio.init();
  }

  /// Adds the initial default prompts (official Google Prompt DJ guide).
  void addInitialPrompts() {
    for (final p in kInitialMusicPrompts) {
      addPrompt(p.key, p.value);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _session?.close();
    _audio.dispose();
    for (final controller in _promptControllers) {
      controller.dispose();
    }
    visualizerTick.dispose();
    super.dispose();
  }

  void _notice(String message, {Duration? duration}) {
    onNotice?.call(MusicStudioNotice(message, duration: duration));
  }

  // ==========================================================================
  // Prompts
  // ==========================================================================

  void addPrompt(String text, double weight) {
    _promptControllers.add(TextEditingController(text: text));
    _promptWeights.add(weight);
    notifyListeners();
  }

  void removePrompt(int index) {
    if (_promptControllers.length <= 1) {
      _notice('At least one weighted prompt is required.');
      return;
    }
    _promptControllers[index].dispose();
    _promptControllers.removeAt(index);
    _promptWeights.removeAt(index);
    notifyListeners();
  }

  void setPromptWeight(int index, double value) {
    _promptWeights[index] = value;
    notifyListeners();
  }

  // ==========================================================================
  // Visualizer
  // ==========================================================================

  /// Called on every tick of the visualizer animation.
  void tickVisualizer() {
    if (_disposed) return;
    if (_isPlaying) {
      final rand = math.Random();
      for (var i = 0; i < visualizerBars.length; i++) {
        final target = 0.15 + rand.nextDouble() * 0.85;
        visualizerBars[i] = visualizerBars[i] * 0.6 + target * 0.4;
      }
    } else {
      for (var i = 0; i < visualizerBars.length; i++) {
        visualizerBars[i] = visualizerBars[i] * 0.8;
      }
    }
    visualizerTick.value++;
  }

  void _log(String message) {
    if (_disposed) return;
    _logRepo.add(message);
    notifyListeners();
  }

  // ==========================================================================
  // Connection Management
  // ==========================================================================

  void selectModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await requestApiKeySetup?.call();
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    _isConnecting = true;
    _status = MusicStudioStatus.connecting;
    notifyListeners();
    _log('🔌 Connecting to $_selectedModel WebSocket...');

    try {
      final session = await _live.connect(
        apiKey: ApiKeyStore.apiKey,
        model: _selectedModel,
        callbacks: LiveMusicCallbacks(
          onOpen: () {
            _log('🟢 WebSocket connection established');
          },
          onMessage: (message) {
            _handleServerMessage(message);
          },
          onError: (error, st) {
            _log('🚨 Error: $error');
            if (!_disposed) {
              _notice('Live Music Error: $error');
            }
          },
          onClose: (code, reason) {
            _log('🔴 Connection closed: $code ($reason)');
            if (!_disposed) {
              _isConnected = false;
              _isConnecting = false;
              _isPlaying = false;
              _status = MusicStudioStatus.disconnected;
              _session = null;
              notifyListeners();
              onVisualizerStop?.call();
              _audio.stop();
            }
          },
        ),
      );

      if (_disposed) {
        await session.close();
        return;
      }

      _session = session;
      _isConnected = true;
      _isConnecting = false;
      _status = MusicStudioStatus.connected;
      notifyListeners();
      _log('✅ Session active. Sending initial prompts & configuration...');

      // Apply initial prompts & configuration
      sendWeightedPrompts();
      sendGenerationConfig();
    } catch (e) {
      _log('❌ Connection failed: $e');
      if (!_disposed) {
        _isConnecting = false;
        _isConnected = false;
        _status = MusicStudioStatus.failed;
        notifyListeners();
        _notice('Failed to connect: $e');
      }
    }
  }

  Future<void> disconnect() async {
    _log('⏹️ Disconnecting session...');
    onVisualizerStop?.call();
    await _audio.stop();
    await _session?.close();
    _session = null;
    _isConnected = false;
    _isPlaying = false;
    _status = MusicStudioStatus.disconnected;
    notifyListeners();
  }

  void _handleServerMessage(LiveMusicServerMessage message) {
    if (message.setupComplete != null) {
      _log('🎉 Server setupComplete acknowledged');
    }

    if (message.filteredPrompt != null) {
      final fp = message.filteredPrompt!;
      _log('⚠️ Prompt filtered: "${fp.text}" (Reason: ${fp.filteredReason})');
    }

    final chunk = message.audioChunk;
    if (chunk != null && chunk.data != null) {
      final bytes = chunk.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        // Drop in-flight server chunks if user paused or stopped
        if (!_isPlaying) return;

        _audio.appendPcmBytes(bytes);
        _receivedChunksCount++;
        _totalBytesReceived += bytes.length;
        notifyListeners();
      }
    }
  }

  // ==========================================================================
  // Transport & Steering Commands
  // ==========================================================================

  void play() {
    if (_session == null) return;
    _log('▶️ Sending PLAY signal');
    _session!.play();
    _isPlaying = true;
    _status = MusicStudioStatus.streaming;
    notifyListeners();
    onVisualizerStart?.call();
  }

  void pause() {
    if (_session == null) return;
    _log('⏸️ Sending PAUSE signal');
    _session!.pause();
    _audio.clear();
    _isPlaying = false;
    _status = MusicStudioStatus.paused;
    notifyListeners();
    onVisualizerStop?.call();
  }

  void stop() {
    if (_session == null) return;
    _log('⏹️ Sending STOP signal');
    _session!.stop();
    _audio.clear();
    _isPlaying = false;
    _status = MusicStudioStatus.stopped;
    notifyListeners();
    onVisualizerStop?.call();
  }

  void resetContext() {
    if (_session == null) return;
    _log('🔄 Sending RESET_CONTEXT signal (seamless transition)');
    _session!.resetContext();
    _notice(
      'Music context reset. Generating fresh variation seamlessly.',
      duration: const Duration(seconds: 2),
    );
  }

  void sendWeightedPrompts() {
    if (_session == null) return;
    final prompts = <WeightedPrompt>[];
    for (var i = 0; i < _promptControllers.length; i++) {
      final text = _promptControllers[i].text.trim();
      if (text.isNotEmpty) {
        prompts.add(WeightedPrompt(text: text, weight: _promptWeights[i]));
      }
    }

    if (prompts.isEmpty) {
      _notice('Please enter at least one valid prompt text.');
      return;
    }

    _log('🎛️ Updating weighted prompts (${prompts.length} active)...');
    _session!.setWeightedPrompts(prompts);
    _notice(
      'Applied ${prompts.length} weighted prompts to Lyria.',
      duration: const Duration(seconds: 1),
    );
  }

  void sendGenerationConfig() {
    if (_session == null) return;
    final config = LiveMusicGenerationConfig(
      bpm: _bpm,
      scale: _selectedScale,
      musicGenerationMode: _mode,
      temperature: _temperature,
      guidance: _guidance,
      density: _density,
      brightness: _brightness,
      muteBass: _muteBass,
      muteDrums: _muteDrums,
      onlyBassAndDrums: _onlyBassAndDrums,
    );

    _log(
      '⚙️ Updating musicGenerationConfig (BPM: $_bpm, Mode: ${_mode.name})...',
    );
    _session!.setMusicGenerationConfig(config);

    final bpmOrScaleChanged =
        (_lastAppliedBpm != null && _bpm != _lastAppliedBpm) ||
        (_lastAppliedScale != _selectedScale);
    _lastAppliedBpm = _bpm;
    _lastAppliedScale = _selectedScale;

    // Per official Google Lyria documentation: updating BPM or Scale requires reset_context()
    if (bpmOrScaleChanged && _autoResetOnTempoScaleChange) {
      _session!.resetContext();
      _log('🔄 Auto-reset context triggered for new BPM ($_bpm) or Scale');
    }

    _notice(
      bpmOrScaleChanged && _autoResetOnTempoScaleChange
          ? 'Applied config & auto-reset context for new tempo/scale.'
          : 'Music generation configuration updated.',
      duration: const Duration(seconds: 1),
    );
  }

  void applyCrossfader(double value) {
    if (_promptControllers.length < 2) return;
    _crossfaderValue = value;
    // Linear crossfade: value = 0.0 -> A=1.0, B=0.0; value = 1.0 -> A=0.0, B=1.0
    _promptWeights[0] = ((1.0 - value) * 1.0).clamp(0.05, 1.0);
    _promptWeights[1] = (value * 1.0).clamp(0.05, 1.0);
    notifyListeners();

    if (_isConnected) {
      sendWeightedPrompts();
    }
  }

  void addTagToPrompt(String tag) {
    addPrompt(tag, 0.8);
    if (_isConnected) {
      sendWeightedPrompts();
    }
    _notice(
      'Added tag "$tag" to steerable prompts.',
      duration: const Duration(seconds: 1),
    );
  }

  // ==========================================================================
  // Presets
  // ==========================================================================

  void applyPreset(MusicPreset preset) {
    for (final c in _promptControllers) {
      c.dispose();
    }
    _promptControllers.clear();
    _promptWeights.clear();

    for (final p in preset.prompts) {
      _promptControllers.add(TextEditingController(text: p.key));
      _promptWeights.add(p.value);
    }
    _bpm = preset.bpm;
    _selectedScale = preset.scale;
    _mode = preset.mode;
    notifyListeners();

    if (_isConnected) {
      sendWeightedPrompts();
      sendGenerationConfig();
    }
  }

  // ==========================================================================
  // Generation config setters
  // ==========================================================================

  void setBpm(int value) {
    _bpm = value;
    notifyListeners();
  }

  void setScale(Scale? value) {
    _selectedScale = value;
    notifyListeners();
  }

  void setMode(MusicGenerationMode value) {
    _mode = value;
    notifyListeners();
  }

  void setTemperature(double value) {
    _temperature = value;
    notifyListeners();
  }

  void setGuidance(double value) {
    _guidance = value;
    notifyListeners();
  }

  void setDensity(double value) {
    _density = value;
    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value;
    notifyListeners();
  }

  void setMuteBass(bool value) {
    _muteBass = value;
    notifyListeners();
  }

  void setMuteDrums(bool value) {
    _muteDrums = value;
    notifyListeners();
  }

  void setOnlyBassAndDrums(bool value) {
    _onlyBassAndDrums = value;
    notifyListeners();
  }

  void setAutoResetOnTempoScaleChange(bool value) {
    _autoResetOnTempoScaleChange = value;
    notifyListeners();
  }
}
