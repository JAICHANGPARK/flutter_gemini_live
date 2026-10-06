import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show Color, Colors, TextEditingController;
import 'package:gemini_live/gemini_live.dart';

import '../../../data/services/dj_audio_service.dart';
import '../../../data/services/dj_music_service.dart';
import '../../../domain/dj_defaults.dart';
import '../../../domain/models/midi_knob_data.dart';
import '../../../domain/models/midi_log_entry.dart';
import 'dj_midi_box_notice.dart';

/// State + logic for the DJ MIDI Box screen (Lyria RealTime steering).
///
/// The view model never touches a `BuildContext`; it asks the view for things
/// via [onNotice], [requestApiKeySetup] and [onLogAppended].
class DjMidiBoxViewModel extends ChangeNotifier {
  DjMidiBoxViewModel({
    required this.customPromptController,
    DjMusicService? musicService,
    DjAudioService? audioService,
  }) : _music = musicService ?? DjMusicService(),
       _audio = audioService ?? DjAudioService(),
       knobs = createDefaultKnobs();

  final DjMusicService _music;
  final DjAudioService _audio;

  /// Owned by the screen (UI object); the view model reads and writes it.
  final TextEditingController customPromptController;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(DjMidiBoxNotice notice)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  /// Called after a log entry was appended (the view scrolls the log down).
  VoidCallback? onLogAppended;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // Lyria RealTime Session & Audio Player
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isPlaying => _isPlaying;

  /// Audio player handle (the visualizer polls live FFT / waveform from it).
  SoloudLiveAudioPlayer get audioPlayer => _audio.player;

  // Side console panel state
  bool _showSidePanel = true;
  double _customPromptWeight = 0.85;
  bool _customPromptActive = false;

  bool get showSidePanel => _showSidePanel;
  double get customPromptWeight => _customPromptWeight;
  bool get customPromptActive => _customPromptActive;

  // Music parameters
  int _bpm = 120;
  MusicGenerationMode _mode = MusicGenerationMode.QUALITY;
  Scale? _selectedScale;
  double _guidance = 4.0;
  double _density = 0.5;
  double _brightness = 0.5;
  final double _temperature = 1.1;
  bool _muteBass = false;
  bool _muteDrums = false;

  int get bpm => _bpm;
  MusicGenerationMode get mode => _mode;
  Scale? get selectedScale => _selectedScale;
  double get guidance => _guidance;
  double get density => _density;
  double get brightness => _brightness;
  bool get muteBass => _muteBass;
  bool get muteDrums => _muteDrums;

  // Real-time log entries
  final List<MidiLogEntry> _logs = [];
  List<MidiLogEntry> get logs => _logs;
  int _chunkCounter = 0;

  // Real-time audio RMS for beat pulse
  double _rmsLevel = 0.0;
  double get rmsLevel => _rmsLevel;
  Timer? _knobDebounceTimer;

  // 16 Dial Pads matching the reference DJ MIDI Box
  final List<MidiKnobData> knobs;

  void init() {
    _audio.init();
  }

  /// Cancels the pending debounce (called first in the screen's dispose).
  void cancelKnobDebounce() {
    _knobDebounceTimer?.cancel();
  }

  @override
  void dispose() {
    _music.close();
    _audio.dispose();
    _disposed = true;
    super.dispose();
  }

  void _addLog(String text, {Color? color}) {
    if (_disposed) return;
    _logs.add(MidiLogEntry(text, color: color));
    if (_logs.length > 250) {
      _logs.removeAt(0);
    }
    notifyListeners();
    onLogAppended?.call();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ==========================================================================
  // WebSocket Connection & Real-time Steering
  // ==========================================================================

  Future<void> connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await requestApiKeySetup?.call();
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    _isConnecting = true;
    notifyListeners();
    _addLog(
      '🔌 Connecting to Lyria RealTime WebSocket...',
      color: const Color(0xFF38BDF8),
    );

    try {
      final session = await _music.connect(
        apiKey: ApiKeyStore.apiKey,
        callbacks: LiveMusicCallbacks(
          onOpen: () {
            debugPrint('[MidiBox] WebSocket connection opened');
            _addLog(
              '✅ WebSocket opened: Connected to Google Lyria!',
              color: const Color(0xFF34D399),
            );
          },
          onMessage: (message) {
            _handleServerMessage(message);
          },
          onError: (err, st) {
            debugPrint('[MidiBox] Error: $err');
            _addLog('❌ WebSocket Error: $err', color: const Color(0xFFEF4444));
            if (!_disposed) {
              _isConnected = false;
              _isPlaying = false;
              notifyListeners();
            }
          },
          onClose: (code, reason) {
            debugPrint('[MidiBox] Closed: $code ($reason)');
            _addLog(
              '⚠️ WebSocket closed ($code: $reason)',
              color: const Color(0xFFF59E0B),
            );
            if (!_disposed) {
              _isConnected = false;
              _isPlaying = false;
              notifyListeners();
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

      // Send initial active knob prompts and config
      _sendWeightedPrompts();
      _sendGenerationConfig();

      onNotice?.call(
        const DjMidiBoxNotice(
          '🎛️ DJ MIDI Box Connected to Lyria RealTime! Tap ▶ to Play.',
          DjMidiBoxNoticeKind.connected,
        ),
      );
    } catch (e) {
      if (!_disposed) {
        _isConnecting = false;
        notifyListeners();
        _addLog('❌ Connection failed: $e', color: const Color(0xFFEF4444));
        onNotice?.call(
          DjMidiBoxNotice(
            'Connection failed: $e',
            DjMidiBoxNoticeKind.connectionFailed,
          ),
        );
      }
    }
  }

  /// Tapping the ONLINE pill: closes the session (callbacks report the rest).
  void closeSession() => _music.close();

  void _handleServerMessage(LiveMusicServerMessage message) {
    if (message.filteredPrompt != null) {
      _addLog(
        '⚠️ Filtered prompt: ${message.filteredPrompt?.text} (Reason: ${message.filteredPrompt?.filteredReason})',
        color: const Color(0xFFEF4444),
      );
    }

    final chunks = message.serverContent?.audioChunks;
    if (chunks != null && chunks.isNotEmpty) {
      if (!_isPlaying) return;
      var totalBytes = 0;
      for (final chunk in chunks) {
        final bytes = chunk.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          totalBytes += bytes.length;
          _audio.appendPcmBytes(bytes);
          final rms = GeminiLiveAudioUtils.calculateRms(bytes);
          final visualScale = GeminiLiveAudioUtils.toVisualScale(
            rms,
            factor: 2.2,
          );

          if (!_disposed) {
            _rmsLevel = visualScale.clamp(0.0, 1.0);
            notifyListeners();
          }
        }
      }
      _chunkCounter++;
      if (_chunkCounter % 16 == 0) {
        _addLog(
          '🔊 Stream playing: +$totalBytes bytes (48kHz Stereo PCM)',
          color: const Color(0xFF10B981),
        );
      }
    } else {
      final chunk = message.audioChunk;
      if (chunk != null && chunk.data != null) {
        final bytes = chunk.bytes;
        if (bytes != null && bytes.isNotEmpty && _isPlaying) {
          _audio.appendPcmBytes(bytes);
          final rms = GeminiLiveAudioUtils.calculateRms(bytes);
          final visualScale = GeminiLiveAudioUtils.toVisualScale(
            rms,
            factor: 2.2,
          );

          if (!_disposed) {
            _rmsLevel = visualScale.clamp(0.0, 1.0);
            notifyListeners();
          }
        }
      }
    }
  }

  Future<void> togglePlay() async {
    if (!_isConnected) {
      await connect();
      if (!_isConnected) return;
    }

    if (_isPlaying) {
      _music.pause();
      _audio.clear();
      _isPlaying = false;
      _rmsLevel = 0.0;
      notifyListeners();
      _addLog('⏸️ Playback paused', color: Colors.white70);
    } else {
      _music.play();
      _isPlaying = true;
      notifyListeners();
      _addLog('▶️ Playback started', color: const Color(0xFFA855F7));
    }
  }

  void _sendWeightedPrompts() {
    if (!_music.hasSession) return;

    final List<WeightedPrompt> prompts = [];

    // 1. Injected custom text prompt (if active and not empty)
    final customText = customPromptController.text.trim();
    if (_customPromptActive &&
        customText.isNotEmpty &&
        _customPromptWeight > 0.01) {
      prompts.add(
        WeightedPrompt(text: customText, weight: _customPromptWeight),
      );
    }

    // 2. Rotary Dial Prompts
    final active = knobs.where((k) => k.weight > 0.01).toList();
    for (final k in active) {
      prompts.add(WeightedPrompt(text: k.prompt, weight: k.weight));
    }

    if (prompts.isEmpty) {
      // Lyria requires at least one prompt
      prompts.add(
        WeightedPrompt(
          text: 'Ambient synth pad drone with gentle harmonic undertones',
          weight: 0.1,
        ),
      );
    }

    _music.setWeightedPrompts(prompts);
    final summary = prompts
        .map((p) {
          final text = p.text ?? '';
          final display = text.length > 20
              ? '${text.substring(0, 18)}..'
              : text;
          final weightPct = (((p.weight ?? 0.0)) * 100).round();
          return '$display [$weightPct%]';
        })
        .join(' · ');
    _addLog(
      '⚡ Prompts sent (${prompts.length}): $summary',
      color: const Color(0xFFFBBF24),
    );
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
    );

    _music.setMusicGenerationConfig(config);
    _addLog(
      '🎛️ Config updated: $_bpm BPM · ${_mode.name} · ${_selectedScale?.name ?? "Auto Scale"} · Guidance $_guidance',
      color: const Color(0xFF38BDF8),
    );
  }

  // ==========================================================================
  // Knobs
  // ==========================================================================

  void onKnobChanged(int index, double newWeight) {
    knobs[index].weight = newWeight.clamp(0.0, 1.0);
    notifyListeners();
    if (_isConnected) {
      // 100ms debounce during dial drag to avoid flooding WebSocket
      _knobDebounceTimer?.cancel();
      _knobDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (_isConnected) {
          _sendWeightedPrompts();
        }
      });
    }
  }

  void onKnobTapped(int index) {
    _knobDebounceTimer?.cancel();
    // Toggle: if > 0 set to 0.0, if 0 set to 0.75
    if (knobs[index].weight > 0.05) {
      knobs[index].weight = 0.0;
    } else {
      knobs[index].weight = 0.75;
    }
    notifyListeners();
    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  void saveKnobEdit(MidiKnobData knob, String title, String prompt) {
    knob.title = title;
    knob.prompt = prompt;
    notifyListeners();
    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  // ==========================================================================
  // Header / console
  // ==========================================================================

  /// Tap-to-cycle tempo pill.
  void cycleBpm() {
    const bpms = djBpmPresets;
    final currentIdx = bpms.indexOf(_bpm);
    final nextIdx = (currentIdx == -1 ? 3 : currentIdx + 1) % bpms.length;
    _bpm = bpms[nextIdx];
    notifyListeners();
    if (_isConnected) {
      _sendGenerationConfig();
    }
  }

  void toggleSidePanel() {
    _showSidePanel = !_showSidePanel;
    notifyListeners();
  }

  // --- Prompt tab ---

  void setCustomPromptActive(bool val) {
    _customPromptActive = val;
    notifyListeners();
    if (_isConnected) _sendWeightedPrompts();
  }

  void onCustomPromptTextChanged() {
    if (_customPromptActive && _isConnected) {
      _knobDebounceTimer?.cancel();
      _knobDebounceTimer = Timer(const Duration(milliseconds: 350), () {
        if (_isConnected) _sendWeightedPrompts();
      });
    }
  }

  void setCustomPromptWeight(double val) {
    _customPromptWeight = val;
    notifyListeners();
    if (_customPromptActive && _isConnected) {
      _knobDebounceTimer?.cancel();
      _knobDebounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_isConnected) _sendWeightedPrompts();
      });
    }
  }

  void applyCustomPrompt() {
    _customPromptActive = true;
    notifyListeners();
    if (_isConnected) {
      _sendWeightedPrompts();
    } else {
      _addLog(
        'Custom prompt saved: ${customPromptController.text.trim()}',
        color: Colors.white70,
      );
    }
  }

  void applyPreset(String prompt) {
    customPromptController.text = prompt;
    _customPromptActive = true;
    notifyListeners();
    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  // --- Settings tab ---

  void setBpmFromSlider(double val) {
    _bpm = val.round();
    notifyListeners();
    if (_isConnected) {
      _knobDebounceTimer?.cancel();
      _knobDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (_isConnected) _sendGenerationConfig();
      });
    }
  }

  void setBpmPreset(int b) {
    _bpm = b;
    notifyListeners();
    if (_isConnected) _sendGenerationConfig();
  }

  void setMode(MusicGenerationMode m) {
    _mode = m;
    notifyListeners();
    if (_isConnected) _sendGenerationConfig();
  }

  void setScale(Scale? s) {
    _selectedScale = s;
    notifyListeners();
    if (_isConnected) _sendGenerationConfig();
  }

  void _debouncedGenerationConfig() {
    if (_isConnected) {
      _knobDebounceTimer?.cancel();
      _knobDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (_isConnected) _sendGenerationConfig();
      });
    }
  }

  void setGuidance(double val) {
    _guidance = val;
    notifyListeners();
    _debouncedGenerationConfig();
  }

  void setDensity(double val) {
    _density = val;
    notifyListeners();
    _debouncedGenerationConfig();
  }

  void setBrightness(double val) {
    _brightness = val;
    notifyListeners();
    _debouncedGenerationConfig();
  }

  void setMuteBass(bool v) {
    _muteBass = v;
    notifyListeners();
    if (_isConnected) _sendGenerationConfig();
  }

  void setMuteDrums(bool v) {
    _muteDrums = v;
    notifyListeners();
    if (_isConnected) _sendGenerationConfig();
  }
}
