import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'dj_midi_box_page.dart';
import 'foldable_utils.dart';
import 'pro_dj_console_page.dart';
import 'soloud_live_audio_player.dart';
import 'scrollable_app_bar_actions.dart';

/// Interactive Real-time Music Studio powered by Google's Lyria Live models.
///
/// Demonstrates:
/// - Real-time bidirectional WebSocket music streaming (`BidiGenerateMusic`)
/// - Dynamic prompt steering via [WeightedPrompt]
/// - Real-time generation parameters ([LiveMusicGenerationConfig]: BPM, Scale, Density, Brightness, Mute Bass/Drums)
/// - Playback transport control: Play, Pause, Stop, Reset Context
/// - Real-time low-latency linear PCM playback & audio visualization
class LiveMusicStudioPage extends StatefulWidget {
  const LiveMusicStudioPage({super.key});

  @override
  State<LiveMusicStudioPage> createState() => _LiveMusicStudioPageState();
}

class _LiveMusicStudioPageState extends State<LiveMusicStudioPage>
    with SingleTickerProviderStateMixin {
  // Session & Player
  LiveMusicSession? _session;
  LiveMusicService? _musicService;
  late final SoloudLiveAudioPlayer _audioPlayer;

  // Connection & Playback State
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;
  String _statusText = 'Disconnected';
  Color _statusColor = Colors.grey;

  // Selected Model
  String _selectedModel = LiveMusicModels.lyriaRealtimeExp;

  // Stream Metrics
  int _receivedChunksCount = 0;
  int _totalBytesReceived = 0;
  final List<String> _logs = [];

  // Weighted Prompts
  final List<TextEditingController> _promptControllers = [];
  final List<double> _promptWeights = [];

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

  // Prompt DJ Crossfader value [0.0 = Prompt A 100%, 1.0 = Prompt B 100%]
  double _crossfaderValue = 0.5;

  // Visualizer animation
  late final AnimationController _visualizerAnim;
  final List<double> _visualizerBars = List.generate(24, (index) => 0.1);

  @override
  void initState() {
    super.initState();
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
    _audioPlayer.init();

    _visualizerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateVisualizer);

    // Initial default prompts from official Google Prompt DJ guide
    _addPrompt(
      'Minimal techno with deep bass, sparse percussion, and atmospheric synths',
      1.0,
    );
    _addPrompt('Shimmering hi-hats and acid 303 bass', 0.8);
  }

  @override
  void dispose() {
    _visualizerAnim.dispose();
    _session?.close();
    _audioPlayer.dispose();
    for (final controller in _promptControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPrompt(String text, double weight) {
    setState(() {
      _promptControllers.add(TextEditingController(text: text));
      _promptWeights.add(weight);
    });
  }

  void _removePrompt(int index) {
    if (_promptControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one weighted prompt is required.'),
        ),
      );
      return;
    }
    setState(() {
      _promptControllers[index].dispose();
      _promptControllers.removeAt(index);
      _promptWeights.removeAt(index);
    });
  }

  void _updateVisualizer() {
    if (!mounted) return;
    if (_isPlaying) {
      final rand = math.Random();
      setState(() {
        for (var i = 0; i < _visualizerBars.length; i++) {
          final target = 0.15 + rand.nextDouble() * 0.85;
          _visualizerBars[i] = _visualizerBars[i] * 0.6 + target * 0.4;
        }
      });
    } else {
      setState(() {
        for (var i = 0; i < _visualizerBars.length; i++) {
          _visualizerBars[i] = _visualizerBars[i] * 0.8;
        }
      });
    }
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().toIso8601String().substring(11, 19)}] $message',
      );
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  // ==========================================================================
  // Connection Management
  // ==========================================================================

  Future<void> _connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await AppSettingsDialog.show(context);
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    setState(() {
      _isConnecting = true;
      _statusText = 'Connecting to Lyria...';
      _statusColor = Colors.orange;
    });
    _log('🔌 Connecting to $_selectedModel WebSocket...');

    try {
      _musicService = LiveMusicService(
        apiKey: ApiKeyStore.apiKey,
        apiVersion: 'v1alpha',
        logger: (msg) => debugPrint('[LiveMusic] $msg'),
      );

      final session = await _musicService!.connect(
        LiveMusicConnectParameters(
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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Live Music Error: $error')),
                );
              }
            },
            onClose: (code, reason) {
              _log('🔴 Connection closed: $code ($reason)');
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isConnecting = false;
                  _isPlaying = false;
                  _statusText = 'Disconnected';
                  _statusColor = Colors.grey;
                  _session = null;
                });
                _visualizerAnim.stop();
                _audioPlayer.stop();
              }
            },
          ),
        ),
      );

      if (!mounted) {
        await session.close();
        return;
      }

      setState(() {
        _session = session;
        _isConnected = true;
        _isConnecting = false;
        _statusText = 'Connected (Ready)';
        _statusColor = Colors.teal;
      });
      _log('✅ Session active. Sending initial prompts & configuration...');

      // Apply initial prompts & configuration
      _sendWeightedPrompts();
      _sendGenerationConfig();
    } catch (e) {
      _log('❌ Connection failed: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _statusText = 'Connection failed';
          _statusColor = Colors.red;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  Future<void> _disconnect() async {
    _log('⏹️ Disconnecting session...');
    _visualizerAnim.stop();
    await _audioPlayer.stop();
    await _session?.close();
    setState(() {
      _session = null;
      _isConnected = false;
      _isPlaying = false;
      _statusText = 'Disconnected';
      _statusColor = Colors.grey;
    });
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

        _audioPlayer.appendPcmBytes(bytes);
        setState(() {
          _receivedChunksCount++;
          _totalBytesReceived += bytes.length;
        });
      }
    }
  }

  // ==========================================================================
  // Transport & Steering Commands
  // ==========================================================================

  void _play() {
    if (_session == null) return;
    _log('▶️ Sending PLAY signal');
    _session!.play();
    setState(() {
      _isPlaying = true;
      _statusText = 'Streaming Audio';
      _statusColor = Colors.greenAccent.shade700;
    });
    _visualizerAnim.repeat(reverse: true);
  }

  void _pause() {
    if (_session == null) return;
    _log('⏸️ Sending PAUSE signal');
    _session!.pause();
    _audioPlayer.clear();
    setState(() {
      _isPlaying = false;
      _statusText = 'Paused';
      _statusColor = Colors.amber;
    });
    _visualizerAnim.stop();
  }

  void _stop() {
    if (_session == null) return;
    _log('⏹️ Sending STOP signal');
    _session!.stop();
    _audioPlayer.clear();
    setState(() {
      _isPlaying = false;
      _statusText = 'Stopped (Context Reset)';
      _statusColor = Colors.blueGrey;
    });
    _visualizerAnim.stop();
  }

  void _resetContext() {
    if (_session == null) return;
    _log('🔄 Sending RESET_CONTEXT signal (seamless transition)');
    _session!.resetContext();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Music context reset. Generating fresh variation seamlessly.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendWeightedPrompts() {
    if (_session == null) return;
    final prompts = <WeightedPrompt>[];
    for (var i = 0; i < _promptControllers.length; i++) {
      final text = _promptControllers[i].text.trim();
      if (text.isNotEmpty) {
        prompts.add(WeightedPrompt(text: text, weight: _promptWeights[i]));
      }
    }

    if (prompts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one valid prompt text.'),
        ),
      );
      return;
    }

    _log('🎛️ Updating weighted prompts (${prompts.length} active)...');
    _session!.setWeightedPrompts(prompts);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${prompts.length} weighted prompts to Lyria.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _sendGenerationConfig() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bpmOrScaleChanged && _autoResetOnTempoScaleChange
              ? 'Applied config & auto-reset context for new tempo/scale.'
              : 'Music generation configuration updated.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyCrossfader(double value) {
    if (_promptControllers.length < 2) return;
    setState(() {
      _crossfaderValue = value;
      // Linear crossfade: value = 0.0 -> A=1.0, B=0.0; value = 1.0 -> A=0.0, B=1.0
      _promptWeights[0] = ((1.0 - value) * 1.0).clamp(0.05, 1.0);
      _promptWeights[1] = (value * 1.0).clamp(0.05, 1.0);
    });

    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  void _addTagToPrompt(String tag) {
    setState(() {
      _addPrompt(tag, 0.8);
    });
    if (_isConnected) {
      _sendWeightedPrompts();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added tag "$tag" to steerable prompts.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ==========================================================================
  // Presets
  // ==========================================================================

  void _applyPreset({
    required List<MapEntry<String, double>> prompts,
    required int bpm,
    Scale? scale,
    required MusicGenerationMode mode,
  }) {
    setState(() {
      for (final c in _promptControllers) {
        c.dispose();
      }
      _promptControllers.clear();
      _promptWeights.clear();

      for (final p in prompts) {
        _promptControllers.add(TextEditingController(text: p.key));
        _promptWeights.add(p.value);
      }
      _bpm = bpm;
      _selectedScale = scale;
      _mode = mode;
    });

    if (_isConnected) {
      _sendWeightedPrompts();
      _sendGenerationConfig();
    }
  }

  // ==========================================================================
  // Build UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkSurface = const Color(0xFF13151A);
    final foldableInfo = FoldableLayoutInfo.of(context);

    Widget foldablePill() {
      if (!foldableInfo.hasHinge && !foldableInfo.isFoldableOrWide) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: foldableInfo.isTabletop
              ? Colors.deepOrangeAccent.withValues(alpha: 0.2)
              : Colors.purpleAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: foldableInfo.isTabletop
                ? Colors.deepOrangeAccent
                : Colors.purpleAccent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              foldableInfo.isTabletop
                  ? Icons.laptop_chromebook_rounded
                  : (foldableInfo.isDualScreen
                        ? Icons.splitscreen_rounded
                        : Icons.developer_board_rounded),
              size: 13,
              color: foldableInfo.isTabletop
                  ? Colors.deepOrangeAccent
                  : Colors.purpleAccent,
            ),
            const SizedBox(width: 4),
            Text(
              foldableInfo.isTabletop
                  ? 'TABLETOP'
                  : (foldableInfo.isDualScreen ? 'DUO' : 'FOLD'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: foldableInfo.isTabletop
                    ? Colors.deepOrangeAccent
                    : Colors.purpleAccent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkSurface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            const Text(
              'Live Music Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
              ),
              child: const Text(
                'Lyria Realtime',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ScrollableAppBarActions(
            children: [
              foldablePill(),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DjMidiBoxPage()),
                  );
                },
                icon: const Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Color(0xFFA855F7),
                ),
                label: const Text(
                  'MIDI BOX',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF261840),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProDjConsolePage()),
                  );
                },
                icon: const Icon(
                  Icons.album_rounded,
                  size: 16,
                  color: Color(0xFF00E5FF),
                ),
                label: const Text(
                  'DJ CONSOLE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2638),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const LanguageSelectorButton(compact: true),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => AppSettingsDialog.show(context),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 1. Tabletop / Flex mode (Foldable resting on flat surface)
          // Top Screen (Upright): Connection Card & Realtime Visualizer HUD
          // Bottom Screen (Flat): Transport Controls, Steerable Prompts, Config, Diagnostics
          if (foldableInfo.isTabletop) {
            return Column(
              children: [
                Expanded(
                  flex: 1,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildConnectionCard(theme),
                      const SizedBox(height: 12),
                      _buildVisualizerCard(theme),
                    ],
                  ),
                ),
                Container(
                  height: 3,
                  color: Colors.purpleAccent.withValues(alpha: 0.6),
                ),
                Expanded(
                  flex: 1,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildTransportControls(theme),
                      const SizedBox(height: 12),
                      _buildPromptsSection(theme),
                      const SizedBox(height: 12),
                      _buildGenerationConfigSection(theme),
                      const SizedBox(height: 12),
                      _buildDiagnosticsPanel(theme),
                    ],
                  ),
                ),
              ],
            );
          }

          // 2. Dual-Screen Book Mode (Surface Duo) or Foldable Unfolded or Wide Screen
          final isTwoPane =
              (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
              foldableInfo.isFoldableOrWide ||
              constraints.maxWidth >= 850;

          if (isTwoPane) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left pane: Monitor, Visualizer, Transport, Diagnostics
                Expanded(
                  flex: 5,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildConnectionCard(theme),
                      const SizedBox(height: 16),
                      _buildVisualizerCard(theme),
                      const SizedBox(height: 16),
                      _buildTransportControls(theme),
                      const SizedBox(height: 16),
                      _buildDiagnosticsPanel(theme),
                    ],
                  ),
                ),
                if (foldableInfo.isDualScreen)
                  SizedBox(
                    width: (foldableInfo.hingeBounds?.width ?? 16).clamp(
                      8.0,
                      36.0,
                    ),
                    child: Container(color: Colors.black),
                  )
                else
                  const VerticalDivider(color: Colors.white12, width: 1),
                // Right pane: Prompts & Music Config
                Expanded(
                  flex: 5,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPromptsSection(theme),
                      const SizedBox(height: 16),
                      _buildGenerationConfigSection(theme),
                    ],
                  ),
                ),
              ],
            );
          }

          // 3. Default single-screen mobile portrait
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildConnectionCard(theme),
              const SizedBox(height: 16),
              _buildVisualizerCard(theme),
              const SizedBox(height: 16),
              _buildTransportControls(theme),
              const SizedBox(height: 16),
              _buildPromptsSection(theme),
              const SizedBox(height: 16),
              _buildGenerationConfigSection(theme),
              const SizedBox(height: 16),
              _buildDiagnosticsPanel(theme),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI Section Builders
  // --------------------------------------------------------------------------

  Widget _buildConnectionCard(ThemeData theme) {
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    dropdownColor: const Color(0xFF242936),
                    decoration: const InputDecoration(
                      labelText: 'Lyria Live Model',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: LiveMusicModels.lyriaRealtimeExp,
                        child: Text(
                          'lyria-realtime-exp (Standard)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: _isConnected
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedModel = val);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : _isConnected
                      ? _disconnect
                      : _connect,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isConnected ? Icons.link_off : Icons.link),
                  label: Text(_isConnected ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected
                        ? Colors.red.shade700
                        : Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'Chunks: $_receivedChunksCount · ${(_totalBytesReceived / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizerCard(ThemeData theme) {
    return Card(
      color: const Color(0xFF181B23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Real-time Stream Visualizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? Colors.green.withAlpha(40)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isPlaying ? 'PCM 48kHz LIVE' : 'STREAM IDLE',
                    style: TextStyle(
                      color: _isPlaying ? Colors.greenAccent : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_visualizerBars.length, (index) {
                  final heightRatio = _visualizerBars[index].clamp(0.05, 1.0);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: 6,
                    height: 70 * heightRatio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          HSVColor.fromAHSV(
                            1.0,
                            (index * 14.0) % 360,
                            0.8,
                            0.9,
                          ).toColor(),
                          Colors.purple.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportControls(ThemeData theme) {
    return Card(
      color: const Color(0xFF1E222D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Play
            IconButton.filled(
              iconSize: 28,
              onPressed: _isConnected && !_isPlaying ? _play : null,
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Start / Resume Generation',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Pause
            IconButton.filled(
              iconSize: 28,
              onPressed: _isConnected && _isPlaying ? _pause : null,
              icon: const Icon(Icons.pause_rounded),
              tooltip: 'Pause Stream',
              style: IconButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Stop
            IconButton.filled(
              iconSize: 28,
              onPressed: _isConnected ? _stop : null,
              icon: const Icon(Icons.stop_rounded),
              tooltip: 'Stop & Reset Context',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Reset Context (Seamless)
            OutlinedButton.icon(
              onPressed: _isConnected ? _resetContext : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Context'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(
                  color: _isConnected ? Colors.cyanAccent : Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptsSection(ThemeData theme) {
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎛️ Steerable Weighted Prompts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addPrompt('', 0.5),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Prompt'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Presets matching official Google Lyria guide
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _presetChip(
                    'Minimal Techno',
                    [
                      const MapEntry(
                        'Minimal techno with deep bass, sparse percussion, and atmospheric synths',
                        1.0,
                      ),
                      const MapEntry(
                        'Shimmering hi-hats and acid 303 bass',
                        0.8,
                      ),
                    ],
                    bpm: 128,
                    mode: MusicGenerationMode.QUALITY,
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    'Lo-Fi Study Beat',
                    [
                      const MapEntry(
                        'Lo-fi hip hop beat with dusty vinyl crackle',
                        1.0,
                      ),
                      const MapEntry(
                        'Mellow Rhodes piano chords & warm upright bassline',
                        0.8,
                      ),
                    ],
                    bpm: 82,
                    scale: Scale.C_MAJOR_A_MINOR,
                    mode: MusicGenerationMode.QUALITY,
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    'Cyberpunk 110',
                    [
                      const MapEntry(
                        'Dark, cinematic cyberpunk synthwave in D minor',
                        1.0,
                      ),
                      const MapEntry(
                        'Heavy distorted 303 bass & analog synths',
                        0.8,
                      ),
                    ],
                    bpm: 110,
                    scale: Scale.D_MAJOR_B_MINOR,
                    mode: MusicGenerationMode.QUALITY,
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    'Ambient Drone',
                    [
                      const MapEntry(
                        'Ambient synth pads with ethereal strings',
                        1.0,
                      ),
                      const MapEntry('Subtle reverberant piano', 0.7),
                    ],
                    bpm: 72,
                    mode: MusicGenerationMode.DIVERSITY,
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    'Afrobeat Groove',
                    [
                      const MapEntry('Afrobeat rhythm & brass section', 1.0),
                      const MapEntry(
                        'Funky bassline and percussion groove',
                        0.7,
                      ),
                    ],
                    bpm: 118,
                    mode: MusicGenerationMode.QUALITY,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Prompt DJ Crossfader (A <-> B)
            if (_promptControllers.length >= 2) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF222733),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.tune,
                              color: Colors.purpleAccent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Prompt DJ Crossfader (A ⟷ B)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'A: ${(1.0 - _crossfaderValue).toStringAsFixed(2)} · B: ${_crossfaderValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: Colors.purpleAccent,
                        inactiveTrackColor: Colors.cyanAccent,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _crossfaderValue,
                        min: 0.0,
                        max: 1.0,
                        onChanged: _applyCrossfader,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Prompt DJ Tag Bank (Keyword Palette)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: const Row(
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Prompt DJ Tag Bank (Official Guide Vocabularies)',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Genres
                    _tagChip('Minimal Techno', Colors.indigo),
                    _tagChip('Deep House', Colors.indigo),
                    _tagChip('Synthpop', Colors.indigo),
                    _tagChip('Lo-Fi Hip Hop', Colors.indigo),
                    _tagChip('Afrobeat', Colors.indigo),
                    _tagChip('Bossa Nova', Colors.indigo),
                    _tagChip('Acid Jazz', Colors.indigo),
                    _tagChip('Drum & Bass', Colors.indigo),
                    // Synths & Keys
                    _tagChip('Moog Oscillations', Colors.deepPurple),
                    _tagChip('303 Acid Bass', Colors.deepPurple),
                    _tagChip('Rhodes Piano', Colors.deepPurple),
                    _tagChip('Mellotron', Colors.deepPurple),
                    _tagChip('Synth Pads', Colors.deepPurple),
                    _tagChip('Dirty Synths', Colors.deepPurple),
                    // Drums & Bass
                    _tagChip('TR-909 Drum Machine', Colors.teal),
                    _tagChip('808 Hip Hop Beat', Colors.teal),
                    _tagChip('Funk Drums', Colors.teal),
                    _tagChip('Boomy Bass', Colors.teal),
                    _tagChip('Tabla', Colors.teal),
                    // Acoustic & Textures
                    _tagChip('Alto Saxophone', Colors.orange),
                    _tagChip('Warm Acoustic Guitar', Colors.orange),
                    _tagChip('Cello', Colors.orange),
                    _tagChip('Harmonica', Colors.orange),
                    _tagChip('Dusty vinyl crackle', Colors.blueGrey),
                    _tagChip('Distorted 303 bassline', Colors.blueGrey),
                    _tagChip('Atmospheric synths', Colors.blueGrey),
                    _tagChip('Subtle sub bass', Colors.blueGrey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dynamic Prompt Rows
            ...List.generate(_promptControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _promptControllers[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Prompt style, instrument, or vibe...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF262C38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weight: ${_promptWeights[index].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: _promptWeights[index],
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Colors.purpleAccent,
                              onChanged: (val) {
                                setState(() => _promptWeights[index] = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => _removePrompt(index),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnected ? _sendWeightedPrompts : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Update Steerable Prompts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(
    String label,
    List<MapEntry<String, double>> prompts, {
    required int bpm,
    Scale? scale,
    required MusicGenerationMode mode,
  }) {
    return ActionChip(
      backgroundColor: const Color(0xFF2B3242),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      onPressed: () =>
          _applyPreset(prompts: prompts, bpm: bpm, scale: scale, mode: mode),
    );
  }

  Widget _tagChip(String label, Color color) {
    return ActionChip(
      backgroundColor: color.withAlpha(50),
      side: BorderSide(color: color.withAlpha(120)),
      avatar: Icon(Icons.add, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () => _addTagToPrompt(label),
    );
  }

  Widget _buildGenerationConfigSection(ThemeData theme) {
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Music Generation Parameters',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // BPM Slider
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'BPM: $_bpm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: 60,
                    max: 200,
                    divisions: 140,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => setState(() => _bpm = val.round()),
                  ),
                ),
              ],
            ),

            // Scale Selector
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Scale / Key:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButton<Scale?>(
                    value: _selectedScale,
                    dropdownColor: const Color(0xFF262C38),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Colors.white24),
                    items: [
                      const DropdownMenuItem<Scale?>(
                        value: null,
                        child: Text('Default / Free Scale'),
                      ),
                      ...Scale.values
                          .where((s) => s != Scale.SCALE_UNSPECIFIED)
                          .map(
                            (s) => DropdownMenuItem<Scale?>(
                              value: s,
                              child: Text(s.name.replaceAll('_', ' ')),
                            ),
                          ),
                    ],
                    onChanged: (val) => setState(() => _selectedScale = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Selector
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Mode:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SegmentedButton<MusicGenerationMode>(
                    segments: const [
                      ButtonSegment(
                        value: MusicGenerationMode.QUALITY,
                        label: Text('Quality', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: MusicGenerationMode.DIVERSITY,
                        label: Text(
                          'Diversity',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      ButtonSegment(
                        value: MusicGenerationMode.VOCALIZATION,
                        label: Text('Vocal', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (val) =>
                        setState(() => _mode = val.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.purple.shade700,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sliders: Temperature, Guidance, Density, Brightness
            _buildParamSlider('Variance (Temp)', _temperature, 0.0, 3.0, (v) {
              setState(() => _temperature = v);
            }),
            _buildParamSlider('Guidance (Prompt)', _guidance, 0.0, 6.0, (v) {
              setState(() => _guidance = v);
            }),
            _buildParamSlider('Density', _density, 0.0, 1.0, (v) {
              setState(() => _density = v);
            }),
            _buildParamSlider('Brightness', _brightness, 0.0, 1.0, (v) {
              setState(() => _brightness = v);
            }),
            const SizedBox(height: 8),

            // Stems & Mute Toggles
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: const Text('Mute Bass'),
                  selected: _muteBass,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: (val) => setState(() => _muteBass = val),
                ),
                FilterChip(
                  label: const Text('Mute Drums'),
                  selected: _muteDrums,
                  selectedColor: Colors.deepOrange.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: (val) => setState(() => _muteDrums = val),
                ),
                FilterChip(
                  label: const Text('Only Bass & Drums'),
                  selected: _onlyBassAndDrums,
                  selectedColor: Colors.teal.withAlpha(100),
                  checkmarkColor: Colors.white,
                  onSelected: (val) => setState(() => _onlyBassAndDrums = val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auto-reset context on BPM/Scale change (Google Lyria docs best practice)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoResetOnTempoScaleChange,
              title: const Text(
                'Auto-reset Context on BPM/Scale change',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Lyria docs: BPM/Scale changes require resetContext() for new tempo/key adoption.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              activeThumbColor: Colors.purpleAccent,
              onChanged: (val) =>
                  setState(() => _autoResetOnTempoScaleChange = val),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnected ? _sendGenerationConfig : null,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Apply Generation Config'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label: ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsPanel(ThemeData theme) {
    return Card(
      color: const Color(0xFF14171F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text(
          '📜 Diagnostics & Stream Logs',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Connect to start streaming.',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
