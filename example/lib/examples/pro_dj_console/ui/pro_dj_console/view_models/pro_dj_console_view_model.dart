import 'dart:async';
import 'dart:math' as math;

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../data/services/pro_dj_audio_service.dart';
import '../../../data/services/pro_dj_music_service.dart';
import '../../../domain/hot_cue_pads.dart';
import '../../../domain/models/hot_cue_pad_data.dart';
import 'pro_dj_console_notice.dart';

/// State and logic of the Pro DJ Console: Lyria RealTime session, mixer
/// controls, transport, hot cue pads, metering and diagnostics log.
class ProDjConsoleViewModel extends ChangeNotifier {
  ProDjConsoleViewModel({
    ProDjMusicService? musicService,
    ProDjAudioService? audioService,
  }) : _music = musicService ?? ProDjMusicService(),
       _audio = audioService ?? ProDjAudioService();

  final ProDjMusicService _music;
  final ProDjAudioService _audio;

  /// Shows a transient message (snackbar) in the view.
  void Function(ProDjConsoleNotice notice)? onNotice;

  /// Opens the API key / settings dialog; resolves to true when changed.
  Future<bool?> Function()? requestApiKeySetup;

  /// Jog wheel animation controls, wired by the screen (which owns the
  /// AnimationController).
  void Function()? startJog;
  void Function()? stopJog;
  void Function()? disposeJog;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // Session state
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isPlaying => _isPlaying;

  // Deck A & Deck B Prompts
  String _deckAPrompt =
      'Minimal techno with deep 909 kick and atmospheric synths';
  String _deckBPrompt = 'Acid 303 bassline with shimmering percussion';
  double _deckAWeight = 1.0;
  double _deckBWeight = 0.5;

  String get deckAPrompt => _deckAPrompt;
  String get deckBPrompt => _deckBPrompt;
  double get deckAWeight => _deckAWeight;
  double get deckBWeight => _deckBWeight;

  // Crossfader: 0.0 (Deck A 100%) <---> 1.0 (Deck B 100%)
  double _crossfader = 0.5;
  double get crossfader => _crossfader;

  // DJM Mixer Controls
  int _bpm = 128;
  int? _lastAppliedBpm;
  Scale? _selectedScale = Scale.D_MAJOR_B_MINOR;
  Scale? _lastAppliedScale;
  MusicGenerationMode _mode = MusicGenerationMode.QUALITY;

  int get bpm => _bpm;
  Scale? get selectedScale => _selectedScale;
  MusicGenerationMode get mode => _mode;

  double _temperature = 1.1; // Trim / Variance
  double _brightness = 0.5; // HI EQ
  double _density = 0.5; // MID EQ
  double _guidance = 4.0; // LOW EQ (1.0 to 6.0)

  double get temperature => _temperature;
  double get brightness => _brightness;
  double get density => _density;
  double get guidance => _guidance;

  // Stem Isolators (Kill Switches)
  bool _muteBass = false;
  bool _muteDrums = false;
  bool _onlyBassAndDrums = false;
  final bool _autoResetOnTempoScaleChange = true;

  bool get muteBass => _muteBass;
  bool get muteDrums => _muteDrums;
  bool get onlyBassAndDrums => _onlyBassAndDrums;

  // Real-time audio metering
  double _currentRmsL = 0.0;
  double _currentRmsR = 0.0;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  double get currentRmsL => _currentRmsL;
  double get currentRmsR => _currentRmsR;
  Duration get elapsed => _elapsed;

  // Active Hot Cue Pad
  int _activePadIndex = 0;
  int get activePadIndex => _activePadIndex;

  // Diagnostics log
  final List<String> _consoleLogs = [];
  List<String> get consoleLogs => _consoleLogs;

  // Hot Cue Pad Presets
  final List<HotCuePadData> _hotCuePads = defaultHotCuePads;
  List<HotCuePadData> get hotCuePads => _hotCuePads;

  void init() {
    _audio.init();

    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPlaying && !_disposed) {
        _elapsed += const Duration(milliseconds: 100);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _elapsedTimer?.cancel();
    disposeJog?.call();
    _music.close();
    _audio.dispose();
    super.dispose();
  }

  void _log(String msg) {
    if (_disposed) return;
    _consoleLogs.insert(
      0,
      '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg',
    );
    if (_consoleLogs.length > 50) _consoleLogs.removeLast();
    notifyListeners();
  }

  // ==========================================================================
  // Connection & Streaming
  // ==========================================================================

  Future<void> connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await requestApiKeySetup?.call();
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    _isConnecting = true;
    notifyListeners();
    _log('Connecting to Google Gemini Lyria RealTime WebSocket...');

    try {
      final session = await _music.connect(
        LiveMusicCallbacks(
          onOpen: () {
            _log('🟢 Deck WebSocket connection established');
          },
          onMessage: (message) {
            _onMessage(message);
          },
          onError: (err, st) {
            _log('⚠️ Stream error: $err');
            if (!_disposed) {
              _isConnected = false;
              _isPlaying = false;
              notifyListeners();
            }
          },
          onClose: (code, reason) {
            _log('🔴 Connection closed: $code ($reason)');
            if (!_disposed) {
              _isConnected = false;
              _isPlaying = false;
              notifyListeners();
              stopJog?.call();
            }
          },
        ),
      );

      if (_disposed) {
        await session.close();
        return;
      }

      _music.attach(session);
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
      _log('Connected to Lyria RealTime! Initializing DJ Decks...');

      // Apply initial setup
      _sendWeightedPrompts();
      _sendGenerationConfig();

      onNotice?.call(
        const ProDjConsoleNotice(
          '🎧 Pro DJ Console Connected to Lyria RealTime!',
          ProDjConsoleNoticeKind.connected,
        ),
      );
    } catch (e) {
      if (!_disposed) {
        _isConnecting = false;
        notifyListeners();
        _log('Connection failed: $e');
        onNotice?.call(
          ProDjConsoleNotice(
            'Connection failed: $e',
            ProDjConsoleNoticeKind.error,
          ),
        );
      }
    }
  }

  void disconnect() => _music.close();

  void _onMessage(LiveMusicServerMessage message) {
    final chunk = message.audioChunk;
    if (chunk != null && chunk.data != null) {
      final bytes = chunk.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        // Discard in-flight server chunks if user paused or stopped
        if (!_isPlaying) return;

        _audio.appendPcmBytes(bytes);

        // Calculate RMS for DJ VU meters & Jog display
        final rms = GeminiLiveAudioUtils.calculateRms(bytes);
        final visualScale = GeminiLiveAudioUtils.toVisualScale(
          rms,
          factor: 2.2,
        );

        final randSkew = (math.Random().nextDouble() - 0.5) * 0.15;
        if (!_disposed) {
          _currentRmsL = visualScale.clamp(0.0, 1.0);
          _currentRmsR = (visualScale + randSkew).clamp(0.0, 1.0);
          notifyListeners();
        }
      }
    }
  }

  Future<void> play() async {
    if (!_music.hasSession) return;
    _log('▶ [PLAY] Starting music playback stream...');
    _music.play();
    _isPlaying = true;
    notifyListeners();
    startJog?.call();
  }

  Future<void> pause() async {
    if (!_music.hasSession) return;
    _log('⏸ [PAUSE] Pausing stream playback...');
    _music.pause();
    _audio.clear();
    _isPlaying = false;
    _currentRmsL = 0.0;
    _currentRmsR = 0.0;
    notifyListeners();
    stopJog?.call();
  }

  Future<void> stop() async {
    if (!_music.hasSession) return;
    _log('⏹ [CUE/STOP] Stopping stream...');
    _music.stop();
    _audio.clear();
    _isPlaying = false;
    _currentRmsL = 0.0;
    _currentRmsR = 0.0;
    notifyListeners();
    stopJog?.call();
  }

  Future<void> resetContext() async {
    if (!_music.hasSession) return;
    _log('🔥 [HARD DROP / RESET CONTEXT] Executing instant context reset...');
    _music.resetContext();
    onNotice?.call(
      const ProDjConsoleNotice(
        '⚡ Instant Beat Drop: Context reset executed!',
        ProDjConsoleNoticeKind.hardDrop,
      ),
    );
  }

  void _sendWeightedPrompts() {
    if (!_music.hasSession) return;

    // Crossfader calculates effective weights
    // Crossfader: 0.0 -> A=1.0, B=0.0; 0.5 -> A=1.0, B=1.0; 1.0 -> A=0.0, B=1.0
    final aMul = (_crossfader <= 0.5) ? 1.0 : (1.0 - _crossfader) * 2.0;
    final bMul = (_crossfader >= 0.5) ? 1.0 : _crossfader * 2.0;

    final effA = (_deckAWeight * aMul).clamp(0.05, 1.0);
    final effB = (_deckBWeight * bMul).clamp(0.05, 1.0);

    final prompts = [
      WeightedPrompt(text: _deckAPrompt, weight: effA),
      WeightedPrompt(text: _deckBPrompt, weight: effB),
    ];

    _music.setWeightedPrompts(prompts);
  }

  void _sendGenerationConfig() {
    if (!_music.hasSession) return;

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

    _music.setMusicGenerationConfig(config);

    final bpmOrScaleChanged =
        (_lastAppliedBpm != null && _bpm != _lastAppliedBpm) ||
        (_lastAppliedScale != _selectedScale);
    _lastAppliedBpm = _bpm;
    _lastAppliedScale = _selectedScale;

    if (bpmOrScaleChanged && _autoResetOnTempoScaleChange) {
      _music.resetContext();
      _log('🔄 Auto-reset context on Tempo ($_bpm BPM) / Scale transition');
    }
  }

  void applyHotCuePad(int index) {
    final pad = _hotCuePads[index];
    _activePadIndex = index;
    _deckAPrompt = pad.promptA;
    _deckBPrompt = pad.promptB;
    _bpm = pad.bpm;
    _selectedScale = pad.scale;
    _mode = pad.mode;
    notifyListeners();

    if (_isConnected) {
      _sendWeightedPrompts();
      _sendGenerationConfig();
      if (pad.isHardDrop) {
        resetContext();
      }
    }

    _log(
      '🎛️ Hot Cue Pad [${pad.label}] Triggered (${pad.bpm} BPM, ${pad.mode.name})',
    );
  }

  // ==========================================================================
  // Mixer controls (each mirrors the original setState + send sequence)
  // ==========================================================================

  /// Slider on a deck's steerable prompt card.
  void setDeckWeight(bool isDeckA, double val) {
    if (isDeckA) {
      _deckAWeight = val;
    } else {
      _deckBWeight = val;
    }
    notifyListeners();
    _sendWeightedPrompts();
  }

  /// SYNC button on a deck: resets that deck's weight to 1.0.
  void syncDeckWeight(bool isDeckA) => setDeckWeight(isDeckA, 1.0);

  void setDeckPrompt(bool isDeckA, String text) {
    if (isDeckA) {
      _deckAPrompt = text;
    } else {
      _deckBPrompt = text;
    }
    notifyListeners();
    _sendWeightedPrompts();
  }

  void setCrossfader(double val) {
    _crossfader = val;
    notifyListeners();
    _sendWeightedPrompts();
  }

  void setTemperature(double v) {
    _temperature = v;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setBrightness(double v) {
    _brightness = v;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setDensity(double v) {
    _density = v;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setGuidance(double v) {
    _guidance = v;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setMuteBass(bool val) {
    _muteBass = val;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setMuteDrums(bool val) {
    _muteDrums = val;
    notifyListeners();
    _sendGenerationConfig();
  }

  void setOnlyBassAndDrums(bool val) {
    _onlyBassAndDrums = val;
    notifyListeners();
    _sendGenerationConfig();
  }
}
