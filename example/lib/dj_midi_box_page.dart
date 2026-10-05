import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'foldable_utils.dart';
import 'soloud_live_audio_player.dart';

/// Interactive Prompt DJ MIDI Box inspired by Google AI Studio's Prompt DJ.
///
/// Features:
/// - 4x4 16-pad tactile rotary dial grid with neon halo rings and arc indicators
/// - Real-time continuous prompt steering via Google Gemini Lyria RealTime WebSocket
/// - Tactile touch interaction: drag to turn dials, tap to toggle on/off, long-press to edit prompt
/// - Audio reactive pulse syncing glowing rings to the live stream beat
/// - Responsive layout adapting smoothly to desktop web and mobile screens
class DjMidiBoxPage extends StatefulWidget {
  const DjMidiBoxPage({super.key});

  @override
  State<DjMidiBoxPage> createState() => _DjMidiBoxPageState();
}

class _DjMidiBoxPageState extends State<DjMidiBoxPage>
    with SingleTickerProviderStateMixin {
  // Lyria RealTime Session & Audio Player
  LiveMusicSession? _session;
  late final SoloudLiveAudioPlayer _audioPlayer;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;

  // Side console panel state
  bool _showSidePanel = true;
  final TextEditingController _customPromptController = TextEditingController(
    text:
        'Energetic futuristic dance track with heavy punchy kicks and sparkling synth arpeggios',
  );
  double _customPromptWeight = 0.85;
  bool _customPromptActive = false;

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

  // Real-time log entries
  final List<_MidiLogEntry> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  int _chunkCounter = 0;

  // Real-time audio RMS for beat pulse
  double _rmsLevel = 0.0;
  late final AnimationController _pulseAnim;
  Timer? _knobDebounceTimer;

  // 16 Dial Pads matching the reference DJ MIDI Box
  late final List<_MidiKnobData> _knobs;

  @override
  void initState() {
    super.initState();
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
    _audioPlayer.init();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    // 16 default styles / instruments matching the reference design
    _knobs = [
      // Row 1
      _MidiKnobData(
        title: 'Bossa Nova',
        prompt:
            'Bossa Nova acoustic guitar rhythm with gentle shaker and warm bass',
        color: const Color(0xFF38BDF8), // Sky Blue
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Chillwave',
        prompt:
            'Nostalgic chillwave synthesizer chords with warm analog tape saturation',
        color: const Color(0xFF818CF8), // Indigo
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Drum and Bass',
        prompt:
            'Fast 174 BPM drum and bass rolling breakbeats and reese bassline',
        color: const Color(0xFFFB7185), // Rose
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Post Punk',
        prompt:
            'Post punk angular electric guitar riffs with driving drum machine',
        color: const Color(0xFFF472B6), // Pink
        weight: 0.0,
      ),

      // Row 2
      _MidiKnobData(
        title: 'Shoegaze',
        prompt: 'Swirling ethereal shoegaze wall of fuzzy reverberant guitars',
        color: const Color(0xFFA78BFA), // Lavender
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Funk',
        prompt:
            'Funky slap bass groove with crisp rhythmic rhythm guitar and claps',
        color: const Color(0xFFFBBF24), // Amber
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Chiptune',
        prompt: '8-bit retro gaming chiptune square wave leads and arpeggios',
        color: const Color(0xFFA855F7), // Vibrant Purple (Active in reference!)
        weight: 0.65,
      ),
      _MidiKnobData(
        title: 'Lush Strings',
        prompt:
            'Lush orchestral string ensemble crescendo with cinematic emotional depth',
        color: const Color(0xFF34D399), // Mint Green (Active in reference!)
        weight: 0.80,
      ),

      // Row 3
      _MidiKnobData(
        title: 'Sparkling Arpeggios',
        prompt:
            'Sparkling crystalline synthesizer arpeggios floating over stereo reverb',
        color: const Color(0xFF22D3EE), // Cyan
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Staccato Rhythms',
        prompt:
            'Tight staccato pizzicato rhythms and percussive melodic accents',
        color: const Color(0xFFF97316), // Orange
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Punchy Kick',
        prompt:
            'Punchy deep 4/4 electronic dance kick drum with chest-thumping low end',
        color: const Color(0xFFEF4444), // Red
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Dubstep',
        prompt: 'Heavy dubstep wobble bass growls with half-time snare beat',
        color: const Color(0xFF10B981), // Emerald
        weight: 0.0,
      ),

      // Row 4
      _MidiKnobData(
        title: 'K Pop',
        prompt:
            'High-energy K-Pop dance idol track with infectious bright synth brass hook, punchy sidechained dance-pop 808 bass, crisp percussion claps, and glossy modern Korean pop production',
        color: const Color(0xFFEC4899), // Hot Pink
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Neo Soul',
        prompt:
            'Warm neo soul Fender Rhodes electric piano chords with laid-back swing beat',
        color: const Color(0xFFF59E0B), // Warm Gold
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Trip Hop',
        prompt:
            'Moody Bristol trip hop downtempo vinyl beat with dusty acoustic jazz bass',
        color: const Color(
          0xFF6366F1,
        ), // Royal Purple-Blue (Active in reference!)
        weight: 0.70,
      ),
      _MidiKnobData(
        title: 'Thrash',
        prompt:
            'Aggressive fast thrash metal double-bass drumming and distorted heavy riffs',
        color: const Color(0xFFDC2626), // Crimson
        weight: 0.0,
      ),
    ];
  }

  @override
  void dispose() {
    _knobDebounceTimer?.cancel();
    _customPromptController.dispose();
    _logScrollController.dispose();
    _pulseAnim.dispose();
    _session?.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addLog(String text, {Color? color}) {
    if (!mounted) return;
    setState(() {
      _logs.add(_MidiLogEntry(text, color: color));
      if (_logs.length > 250) {
        _logs.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(
          _logScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // ==========================================================================
  // WebSocket Connection & Real-time Steering
  // ==========================================================================

  Future<void> _connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await AppSettingsDialog.show(context);
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    setState(() => _isConnecting = true);
    _addLog(
      '🔌 Connecting to Lyria RealTime WebSocket...',
      color: const Color(0xFF38BDF8),
    );

    try {
      final musicService = LiveMusicService(
        apiKey: ApiKeyStore.apiKey,
        apiVersion: 'v1alpha',
      );

      final session = await musicService.connect(
        LiveMusicConnectParameters(
          model: LiveMusicModels.lyriaRealtimeExp,
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
              _addLog(
                '❌ WebSocket Error: $err',
                color: const Color(0xFFEF4444),
              );
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isPlaying = false;
                });
              }
            },
            onClose: (code, reason) {
              debugPrint('[MidiBox] Closed: $code ($reason)');
              _addLog(
                '⚠️ WebSocket closed ($code: $reason)',
                color: const Color(0xFFF59E0B),
              );
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isPlaying = false;
                });
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
      });

      // Send initial active knob prompts and config
      _sendWeightedPrompts();
      _sendGenerationConfig();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎛️ DJ MIDI Box Connected to Lyria RealTime! Tap ▶ to Play.',
          ),
          backgroundColor: Colors.deepPurpleAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _addLog('❌ Connection failed: $e', color: const Color(0xFFEF4444));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          _audioPlayer.appendPcmBytes(bytes);
          final rms = GeminiLiveAudioUtils.calculateRms(bytes);
          final visualScale = GeminiLiveAudioUtils.toVisualScale(
            rms,
            factor: 2.2,
          );

          if (mounted) {
            setState(() {
              _rmsLevel = visualScale.clamp(0.0, 1.0);
            });
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
          _audioPlayer.appendPcmBytes(bytes);
          final rms = GeminiLiveAudioUtils.calculateRms(bytes);
          final visualScale = GeminiLiveAudioUtils.toVisualScale(
            rms,
            factor: 2.2,
          );

          if (mounted) {
            setState(() {
              _rmsLevel = visualScale.clamp(0.0, 1.0);
            });
          }
        }
      }
    }
  }

  Future<void> _togglePlay() async {
    if (!_isConnected) {
      await _connect();
      if (!_isConnected) return;
    }

    if (_isPlaying) {
      _session?.pause();
      _audioPlayer.clear();
      setState(() {
        _isPlaying = false;
        _rmsLevel = 0.0;
      });
      _addLog('⏸️ Playback paused', color: Colors.white70);
    } else {
      _session?.play();
      setState(() => _isPlaying = true);
      _addLog('▶️ Playback started', color: const Color(0xFFA855F7));
    }
  }

  void _sendWeightedPrompts() {
    if (_session == null) return;

    final List<WeightedPrompt> prompts = [];

    // 1. Injected custom text prompt (if active and not empty)
    final customText = _customPromptController.text.trim();
    if (_customPromptActive &&
        customText.isNotEmpty &&
        _customPromptWeight > 0.01) {
      prompts.add(
        WeightedPrompt(text: customText, weight: _customPromptWeight),
      );
    }

    // 2. Rotary Dial Prompts
    final active = _knobs.where((k) => k.weight > 0.01).toList();
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

    _session!.setWeightedPrompts(prompts);
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
    );

    _session!.setMusicGenerationConfig(config);
    _addLog(
      '🎛️ Config updated: $_bpm BPM · ${_mode.name} · ${_selectedScale?.name ?? "Auto Scale"} · Guidance $_guidance',
      color: const Color(0xFF38BDF8),
    );
  }

  void _onKnobChanged(int index, double newWeight) {
    setState(() {
      _knobs[index].weight = newWeight.clamp(0.0, 1.0);
    });
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

  void _onKnobTapped(int index) {
    _knobDebounceTimer?.cancel();
    setState(() {
      // Toggle: if > 0 set to 0.0, if 0 set to 0.75
      if (_knobs[index].weight > 0.05) {
        _knobs[index].weight = 0.0;
      } else {
        _knobs[index].weight = 0.75;
      }
    });
    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  void _onKnobLongPressed(int index) {
    final knob = _knobs[index];
    final titleController = TextEditingController(text: knob.title);
    final promptController = TextEditingController(text: knob.prompt);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1438),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Knob: ${knob.title}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Label Badge Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF2D1F50),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Musical Description Prompt',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF2D1F50),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: knob.color,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  knob.title = titleController.text.trim();
                  knob.prompt = promptController.text.trim();
                });
                if (_isConnected) {
                  _sendWeightedPrompts();
                }
                Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // Build UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Rich cosmic dark purple gradient matching reference design
          gradient: RadialGradient(
            center: Alignment(0.4, -0.2),
            radius: 1.3,
            colors: [
              Color(0xFF381566), // Glowing cosmic violet
              Color(0xFF210E40), // Mid purple
              Color(0xFF110724), // Dark deep purple
              Color(0xFF090414), // Near black purple
            ],
            stops: [0.0, 0.45, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final foldableInfo = FoldableLayoutInfo.of(context);

              // 1. Tabletop / Flex Mode (Foldable device half-opened on a table)
              if (foldableInfo.isTabletop) {
                return Column(
                  children: [
                    // Upright Top Screen: Header + Glowing Audio Reactive Visualizer
                    _buildTopHeader(),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                final pulseScale =
                                    1.0 + (_isPlaying ? _rmsLevel * 0.45 : 0.0);
                                return Transform.scale(
                                  scale: pulseScale,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(
                                            0xFFA855F7,
                                          ).withValues(alpha: 0.6),
                                          const Color(
                                            0xFF38BDF8,
                                          ).withValues(alpha: 0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                      border: Border.all(
                                        color: _isPlaying
                                            ? const Color(0xFFA855F7)
                                            : Colors.white24,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.graphic_eq
                                            : Icons.music_note,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isPlaying
                                  ? 'PLAYING · $_bpm BPM'
                                  : 'READY · TAP DIALS TO PLAY',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Physical Hinge Crease
                    Container(height: 4, color: Colors.white10),

                    // Flat Bottom Screen: 4x4 Grid + Bottom Transport Controls
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildKnobGrid(
                              knobIndices: List.generate(
                                _knobs.length,
                                (i) => i,
                              ),
                              crossAxisCount: 4,
                              maxWidth: 680,
                            ),
                            _buildBottomControls(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // 2. Dual-Screen Book Mode (Surface Duo / 2 physical screens)
              if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
                return Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(
                      child: Row(
                        children: [
                          // Left Screen: Pads 1-8
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildKnobGrid(
                                knobIndices: List.generate(8, (i) => i),
                                crossAxisCount: 2,
                                maxWidth: 360,
                              ),
                            ),
                          ),

                          // Hinge Spine Spacer
                          SizedBox(
                            width: (foldableInfo.hingeBounds?.width ?? 16)
                                .clamp(8.0, 36.0),
                            child: Center(
                              child: Container(width: 2, color: Colors.white24),
                            ),
                          ),

                          // Right Screen: Pads 9-16 + Controls
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                children: [
                                  _buildKnobGrid(
                                    knobIndices: List.generate(8, (i) => i + 8),
                                    crossAxisCount: 2,
                                    maxWidth: 360,
                                  ),
                                  _buildBottomControls(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // 3. Desktop / Wide Screen Split View Layout
              if (width >= 860) {
                final leftPanelWidth = math
                    .min(width * 0.35, 420.0)
                    .clamp(320.0, 420.0);
                return Row(
                  children: [
                    if (_showSidePanel)
                      SizedBox(
                        width: leftPanelWidth,
                        child: _buildLeftConsolePanel(),
                      ),
                    if (_showSidePanel)
                      Container(width: 1.5, color: Colors.white12),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopHeader(),
                          Expanded(
                            child: Center(
                              child: _buildKnobGrid(
                                knobIndices: List.generate(
                                  _knobs.length,
                                  (i) => i,
                                ),
                                crossAxisCount: 4,
                                maxWidth: 680,
                              ),
                            ),
                          ),
                          _buildBottomControls(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // 4. Standard Compact & Mobile Layout
              final crossAxisCount = width < 420 ? 2 : (width < 600 ? 3 : 4);

              return Column(
                children: [
                  _buildTopHeader(),
                  Expanded(
                    child: Center(
                      child: _buildKnobGrid(
                        knobIndices: List.generate(_knobs.length, (i) => i),
                        crossAxisCount: crossAxisCount,
                        maxWidth: 680,
                      ),
                    ),
                  ),
                  _buildBottomControls(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKnobGrid({
    required List<int> knobIndices,
    required int crossAxisCount,
    double maxWidth = 680,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.82,
          ),
          itemCount: knobIndices.length,
          itemBuilder: (context, i) {
            final index = knobIndices[i];
            final knob = _knobs[index];
            return _MidiKnobWidget(
              data: knob,
              rmsLevel: _isPlaying ? _rmsLevel : 0.0,
              onChanged: (newVal) => _onKnobChanged(index, newVal),
              onTap: () => _onKnobTapped(index),
              onLongPress: () => _onKnobLongPressed(index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Text(
                'DJ MIDI BOX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          // Status & BPM Pill
          Row(
            children: [
              // BPM Indicator (Tap to cycle tempo)
              InkWell(
                onTap: () {
                  setState(() {
                    const bpms = [84, 96, 110, 120, 128, 140, 174];
                    final currentIdx = bpms.indexOf(_bpm);
                    final nextIdx =
                        (currentIdx == -1 ? 3 : currentIdx + 1) % bpms.length;
                    _bpm = bpms[nextIdx];
                  });
                  if (_isConnected) {
                    _sendGenerationConfig();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_bpm BPM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Connection status
              InkWell(
                onTap: _isConnected ? () => _session?.close() : _connect,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? const Color(0xFF10B981).withAlpha(40)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isConnected
                          ? const Color(0xFF10B981)
                          : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _isConnected
                            ? const Color(0xFF10B981)
                            : Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnecting
                            ? 'CONNECTING'
                            : (_isConnected ? 'ONLINE' : 'CONNECT'),
                        style: TextStyle(
                          color: _isConnected
                              ? const Color(0xFF10B981)
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              const LanguageSelectorButton(compact: true),

              const SizedBox(width: 4),

              // Console Split-View Toggle Button
              IconButton(
                icon: Icon(
                  _showSidePanel
                      ? Icons.space_dashboard
                      : Icons.space_dashboard_outlined,
                  color: _showSidePanel
                      ? const Color(0xFFA855F7)
                      : Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  final width = MediaQuery.of(context).size.width;
                  if (width < 860) {
                    _showMobileConsoleSheet(context);
                  } else {
                    setState(() => _showSidePanel = !_showSidePanel);
                  }
                },
                tooltip: _showSidePanel
                    ? 'Hide Console'
                    : 'Show Console (Prompt, Settings, Logs)',
              ),

              const SizedBox(width: 4),

              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => AppSettingsDialog.show(context),
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DjAudioVisualizer(
          audioPlayer: _audioPlayer,
          isPlaying: _isPlaying,
          knobs: _knobs,
          customPromptText: _customPromptActive
              ? _customPromptController.text
              : null,
          customPromptWeight: _customPromptActive ? _customPromptWeight : null,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 2),
          child: Center(
            child: GestureDetector(
              onTap: _togglePlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Sleek indigo purple circular button matching image
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4C2A85), Color(0xFF2A1550)],
                  ),
                  border: Border.all(
                    color: _isPlaying
                        ? const Color(0xFFA855F7)
                        : Colors.white.withAlpha(40),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isPlaying
                          ? const Color(0xFFA855F7).withAlpha(160)
                          : Colors.black54,
                      blurRadius: _isPlaying ? 20 : 12,
                      spreadRadius: _isPlaying ? 3 : 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // Left Console Panel: Custom Prompt, Settings & Logs
  // ==========================================================================

  static const _presets = [
    (
      'Cyberpunk Synth',
      'Aggressive cyberpunk industrial bassline with dark analog synth arpeggios and punchy drums',
    ),
    (
      'K-Pop Dance',
      'High-energy K-Pop dance idol track with infectious bright synth brass hook, punchy sidechained dance-pop 808 bass, crisp percussion claps, and glossy modern Korean pop production',
    ),
    (
      'Lo-Fi Beats',
      'Chill lo-fi hip hop dusty vinyl crackle with warm Rhodes electric piano and boom bap drums',
    ),
    (
      'Liquid DnB',
      'Smooth 174 BPM liquid drum and bass rolling breakbeats with atmospheric vocal textures',
    ),
    (
      'French House',
      'Groovy disco filtered house pump with funky bass guitar and sidechained 909 drums',
    ),
    (
      'City Pop',
      'Sparkling 80s Japanese city pop brass stabs with slap bass and nostalgic summer vibes',
    ),
  ];

  void _showMobileConsoleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13092C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: _buildLeftConsolePanel(),
        );
      },
    );
  }

  Widget _buildLeftConsolePanel() {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: const Color(0xFF13092C).withAlpha(250),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFFA855F7), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'DJ CONSOLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFA855F7).withAlpha(100),
                      ),
                    ),
                    child: Text(
                      _isPlaying ? 'STREAMING' : 'IDLE',
                      style: const TextStyle(
                        color: Color(0xFFA855F7),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.black.withAlpha(40),
              child: const TabBar(
                indicatorColor: Color(0xFFA855F7),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.edit_note, size: 16), text: 'PROMPT'),
                  Tab(
                    icon: Icon(Icons.settings_input_component, size: 16),
                    text: 'SETTINGS',
                  ),
                  Tab(icon: Icon(Icons.terminal, size: 16), text: 'LOGS'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildPromptTab(),
                  _buildSettingsTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFFFBBF24), size: 16),
            const SizedBox(width: 6),
            const Text(
              'CUSTOM PROMPT INJECTION',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Switch.adaptive(
              value: _customPromptActive,
              activeTrackColor: const Color(0xFFA855F7),
              onChanged: (val) {
                setState(() => _customPromptActive = val);
                if (_isConnected) _sendWeightedPrompts();
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _customPromptActive
              ? 'Active: Steering the music along with the 16 rotary knobs'
              : 'Disabled: Only rotary knobs are active',
          style: TextStyle(
            color: _customPromptActive
                ? const Color(0xFF34D399)
                : Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customPromptController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter real-time music style prompt...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1E123D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFA855F7)),
            ),
          ),
          onChanged: (_) {
            if (_customPromptActive && _isConnected) {
              _knobDebounceTimer?.cancel();
              _knobDebounceTimer = Timer(const Duration(milliseconds: 350), () {
                if (_isConnected) _sendWeightedPrompts();
              });
            }
          },
        ),
        const SizedBox(height: 12),

        // Weight Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prompt Weight (Influence):',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              '${(_customPromptWeight * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFA855F7),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFA855F7),
            trackHeight: 3,
          ),
          child: Slider(
            value: _customPromptWeight,
            min: 0.05,
            max: 1.0,
            onChanged: (val) {
              setState(() => _customPromptWeight = val);
              if (_customPromptActive && _isConnected) {
                _knobDebounceTimer?.cancel();
                _knobDebounceTimer = Timer(
                  const Duration(milliseconds: 150),
                  () {
                    if (_isConnected) _sendWeightedPrompts();
                  },
                );
              }
            },
          ),
        ),

        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA855F7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text(
            'APPLY PROMPT TO MIX',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          onPressed: () {
            setState(() => _customPromptActive = true);
            if (_isConnected) {
              _sendWeightedPrompts();
            } else {
              _addLog(
                'Custom prompt saved: ${_customPromptController.text.trim()}',
                color: Colors.white70,
              );
            }
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'QUICK STYLE PRESETS',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in _presets)
              ActionChip(
                backgroundColor: const Color(0xFF26184A),
                label: Text(
                  preset.$1,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                onPressed: () {
                  setState(() {
                    _customPromptController.text = preset.$2;
                    _customPromptActive = true;
                  });
                  if (_isConnected) {
                    _sendWeightedPrompts();
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BPM
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEMPO (BPM)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              '$_bpm BPM',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF38BDF8),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFF38BDF8),
            trackHeight: 3,
          ),
          child: Slider(
            value: _bpm.toDouble(),
            min: 60,
            max: 180,
            divisions: 120,
            onChanged: (val) {
              setState(() => _bpm = val.round());
              if (_isConnected) {
                _knobDebounceTimer?.cancel();
                _knobDebounceTimer = Timer(
                  const Duration(milliseconds: 200),
                  () {
                    if (_isConnected) _sendGenerationConfig();
                  },
                );
              }
            },
          ),
        ),
        Wrap(
          spacing: 6,
          children: [84, 96, 110, 120, 128, 140, 174].map((b) {
            final isSel = _bpm == b;
            return ChoiceChip(
              selected: isSel,
              selectedColor: const Color(0xFF38BDF8).withAlpha(60),
              backgroundColor: const Color(0xFF1E123D),
              label: Text(
                '$b',
                style: TextStyle(
                  color: isSel ? const Color(0xFF38BDF8) : Colors.white70,
                  fontSize: 10,
                ),
              ),
              onSelected: (_) {
                setState(() => _bpm = b);
                if (_isConnected) _sendGenerationConfig();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 18),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),

        // Generation Mode
        const Text(
          'GENERATION MODE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E123D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MusicGenerationMode>(
              value: _mode,
              dropdownColor: const Color(0xFF1E123D),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: MusicGenerationMode.values
                  .where(
                    (m) =>
                        m !=
                        MusicGenerationMode.MUSIC_GENERATION_MODE_UNSPECIFIED,
                  )
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) {
                if (m != null) {
                  setState(() => _mode = m);
                  if (_isConnected) _sendGenerationConfig();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Scale
        const Text(
          'MUSICAL SCALE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E123D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Scale?>(
              value: _selectedScale,
              dropdownColor: const Color(0xFF1E123D),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Auto Scale (Model Decides)'),
                ),
                ...Scale.values
                    .where((s) => s != Scale.SCALE_UNSPECIFIED)
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name.replaceAll('_', ' ')),
                      ),
                    ),
              ],
              onChanged: (s) {
                setState(() => _selectedScale = s);
                if (_isConnected) _sendGenerationConfig();
              },
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),

        // Guidance Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GUIDANCE SCALE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              _guidance.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: _guidance,
          min: 1.0,
          max: 6.0,
          activeColor: const Color(0xFFFBBF24),
          onChanged: (val) {
            setState(() => _guidance = val);
            if (_isConnected) {
              _knobDebounceTimer?.cancel();
              _knobDebounceTimer = Timer(const Duration(milliseconds: 200), () {
                if (_isConnected) _sendGenerationConfig();
              });
            }
          },
        ),

        // Density Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SOUND DENSITY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              '${(_density * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: _density,
          min: 0.0,
          max: 1.0,
          activeColor: const Color(0xFF34D399),
          onChanged: (val) {
            setState(() => _density = val);
            if (_isConnected) {
              _knobDebounceTimer?.cancel();
              _knobDebounceTimer = Timer(const Duration(milliseconds: 200), () {
                if (_isConnected) _sendGenerationConfig();
              });
            }
          },
        ),

        // Brightness Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BRIGHTNESS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              '${(_brightness * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFFEC4899),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: _brightness,
          min: 0.0,
          max: 1.0,
          activeColor: const Color(0xFFEC4899),
          onChanged: (val) {
            setState(() => _brightness = val);
            if (_isConnected) {
              _knobDebounceTimer?.cancel();
              _knobDebounceTimer = Timer(const Duration(milliseconds: 200), () {
                if (_isConnected) _sendGenerationConfig();
              });
            }
          },
        ),

        const SizedBox(height: 12),
        // Mute bass & drums
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Mute Bass',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          value: _muteBass,
          activeTrackColor: const Color(0xFFEF4444),
          onChanged: (v) {
            setState(() => _muteBass = v);
            if (_isConnected) _sendGenerationConfig();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Mute Drums',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          value: _muteDrums,
          activeTrackColor: const Color(0xFFEF4444),
          onChanged: (v) {
            setState(() => _muteDrums = v);
            if (_isConnected) _sendGenerationConfig();
          },
        ),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.black26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVENTS (${_logs.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _logs.clear()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'CLEAR',
                    style: TextStyle(
                      color: Color(0xFFF43F5E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _logs.isEmpty
              ? const Center(
                  child: Text(
                    'No events logged yet.\nConnect or play to view real-time WebSocket events.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                )
              : ListView.builder(
                  controller: _logScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '[${log.timeFormatted}] ',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Expanded(
                            child: Text(
                              log.text,
                              style: TextStyle(
                                color: log.color,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// Tactile Rotary Dial Knob Widget
// ============================================================================

class _MidiKnobWidget extends StatelessWidget {
  final _MidiKnobData data;
  final double rmsLevel;
  final ValueChanged<double> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MidiKnobWidget({
    required this.data,
    required this.rmsLevel,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data.weight > 0.02;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 80.0;
        final nextWeight = (data.weight + delta).clamp(0.0, 1.0);
        onChanged(nextWeight);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rotary Dial with Glow Halo and Arc
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CustomPaint(
                  painter: _MidiKnobPainter(
                    weight: data.weight,
                    color: data.color,
                    isActive: isActive,
                    pulse: isActive ? rmsLevel : 0.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Label Badge underneath knob
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? data.color.withAlpha(120) : Colors.white10,
                width: 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: data.color.withAlpha(60),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Custom Knob Painter
// ============================================================================

class _MidiKnobPainter extends CustomPainter {
  final double weight;
  final Color color;
  final bool isActive;
  final double pulse;

  _MidiKnobPainter({
    required this.weight,
    required this.color,
    required this.isActive,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Circular Glow Halo when active
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withAlpha((180 + pulse * 75).toInt().clamp(0, 255))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + pulse * 8);

      canvas.drawCircle(center, radius * 0.95, glowPaint);

      // Solid color halo ring behind the knob
      final haloSolidPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.88, haloSolidPaint);
    } else {
      // Inactive dark outer well with subtle bevel
      final wellPaint = Paint()
        ..color = Colors.black.withAlpha(130)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.88, wellPaint);

      final wellBorderPaint = Paint()
        ..color = Colors.white.withAlpha(20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * 0.88, wellBorderPaint);
    }

    // 2. Arc Indicator Track (clockwise from 7 o'clock = 135 deg to 5 o'clock = 405 deg)
    // Total sweep angle = 270 degrees (3 * pi / 2)
    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final sweepAngle = totalSweep * weight.clamp(0.0, 1.0);

    if (isActive) {
      // White clean active arc
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.68),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // 3. Knob Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center.translate(0, 3), radius * 0.54, shadowPaint);

    // 4. White/Silver 3D Physical Knob Cap
    final knobRect = Rect.fromCircle(center: center, radius: radius * 0.54);
    final knobGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.85,
      colors: const [
        Color(0xFFFFFFFF), // Highlight pure white
        Color(0xFFF1F5F9), // Light silver
        Color(0xFFE2E8F0), // Base white/grey
        Color(0xFFCBD5E1), // Bevel shadow edge
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final knobPaint = Paint()..shader = knobGradient.createShader(knobRect);
    canvas.drawCircle(center, radius * 0.54, knobPaint);

    // Subtle edge rim border
    final rimPaint = Paint()
      ..color = const Color(0xFF94A3B8).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.54, rimPaint);

    // 5. Min Reference Dot at 7 o'clock position (outside knob)
    final minDotOffset = Offset(
      center.dx + radius * 0.74 * math.cos(startAngle),
      center.dy + radius * 0.74 * math.sin(startAngle),
    );
    final minDotPaint = Paint()
      ..color = Colors.white.withAlpha(isActive ? 120 : 60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(minDotOffset, 1.8, minDotPaint);

    // 6. Knob Position Dot Indicator (black dot on the knob cap)
    final currentAngle = startAngle + sweepAngle;
    final dotDist = radius * 0.36;
    final dotOffset = Offset(
      center.dx + dotDist * math.cos(currentAngle),
      center.dy + dotDist * math.sin(currentAngle),
    );

    final dotPaint = Paint()
      ..color =
          const Color(0xFF0F172A) // Dark slate black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotOffset, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MidiKnobPainter oldDelegate) {
    return oldDelegate.weight != weight ||
        oldDelegate.isActive != isActive ||
        oldDelegate.pulse != pulse;
  }
}

// ============================================================================
// Knob Data Model
// ============================================================================

class _MidiKnobData {
  String title;
  String prompt;
  final Color color;
  double weight;

  _MidiKnobData({
    required this.title,
    required this.prompt,
    required this.color,
    required this.weight,
  });
}

// ============================================================================
// Real-Time DJ Log Entry Model
// ============================================================================

class _MidiLogEntry {
  final DateTime time;
  final String text;
  final Color color;

  _MidiLogEntry(this.text, {Color? color})
    : time = DateTime.now(),
      color = color ?? const Color(0xFF94A3B8);

  String get timeFormatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ============================================================================
// Real-Time DJ FFT Spectrum & Waveform Visualizer
// ============================================================================

class _DjAudioVisualizer extends StatefulWidget {
  final SoloudLiveAudioPlayer audioPlayer;
  final bool isPlaying;
  final List<_MidiKnobData> knobs;
  final String? customPromptText;
  final double? customPromptWeight;

  const _DjAudioVisualizer({
    required this.audioPlayer,
    required this.isPlaying,
    required this.knobs,
    this.customPromptText,
    this.customPromptWeight,
  });

  @override
  State<_DjAudioVisualizer> createState() => _DjAudioVisualizerState();
}

class _DjAudioVisualizerState extends State<_DjAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  List<double> _fftValues = List.filled(32, 0.0);
  List<double> _peakCaps = List.filled(32, 0.0);
  List<double> _waveform = List.filled(64, 0.0);

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    if (widget.isPlaying) {
      _ticker.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _DjAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _ticker.repeat();
      } else {
        _ticker.stop();
        setState(() {
          _fftValues = List.filled(32, 0.0);
          _peakCaps = List.filled(32, 0.0);
          _waveform = List.filled(64, 0.0);
        });
      }
    }
  }

  void _onTick() {
    if (!widget.isPlaying) return;
    final rawFft = widget.audioPlayer.getLiveFft(count: 32);
    final rawWave = widget.audioPlayer.getLiveWaveform(count: 64);

    final newPeaks = List<double>.from(_peakCaps);
    for (var i = 0; i < 32; i++) {
      final current = rawFft[i];
      if (current >= newPeaks[i]) {
        newPeaks[i] = current;
      } else {
        newPeaks[i] = math.max(0.0, newPeaks[i] - 0.035);
      }
    }

    setState(() {
      _fftValues = rawFft;
      _peakCaps = newPeaks;
      _waveform = rawWave;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate active mix prompt summary string
    final activeKnobs = widget.knobs.where((k) => k.weight > 0.01).toList();
    final double customW =
        (widget.customPromptText != null &&
            widget.customPromptText!.isNotEmpty &&
            (widget.customPromptWeight ?? 0) > 0.01)
        ? (widget.customPromptWeight ?? 0)
        : 0.0;

    final totalWeight =
        activeKnobs.fold<double>(0.0, (acc, k) => acc + k.weight) + customW;

    final List<String> blendParts = [];
    if (customW > 0.0) {
      final pct = ((customW / (totalWeight > 0 ? totalWeight : 1.0)) * 100)
          .round();
      final preview = widget.customPromptText!.length > 14
          ? '${widget.customPromptText!.substring(0, 12)}..'
          : widget.customPromptText!;
      blendParts.add('✍️ "$preview" $pct%');
    }

    for (final k in activeKnobs) {
      final pct = ((k.weight / (totalWeight > 0 ? totalWeight : 1.0)) * 100)
          .round();
      blendParts.add('${k.title} $pct%');
    }

    final String mixSummary = blendParts.isEmpty
        ? 'Ambient Synth (100%)'
        : blendParts.join(' + ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF140D2B).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isPlaying
              ? const Color(0xFFA855F7).withAlpha(140)
              : Colors.white12,
          width: 1.5,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withAlpha(45),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info row: live status + active blend
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isPlaying
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                  boxShadow: widget.isPlaying
                      ? [
                          const BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE FFT & WAVEFORM',
                style: TextStyle(
                  color: widget.isPlaying ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Active Blend Pills
              Flexible(
                child: Text(
                  '🎛️ $mixSummary',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Custom Painter for FFT Bars & Waveform line
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _DjVisualizerPainter(
                fftValues: _fftValues,
                peakCaps: _peakCaps,
                waveform: _waveform,
                isPlaying: widget.isPlaying,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Frequency axis indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SUB BASS (40Hz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LOW-MID (500Hz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'MID-HIGH (4kHz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TREBLE (16kHz)',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DjVisualizerPainter extends CustomPainter {
  final List<double> fftValues;
  final List<double> peakCaps;
  final List<double> waveform;
  final bool isPlaying;

  _DjVisualizerPainter({
    required this.fftValues,
    required this.peakCaps,
    required this.waveform,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Draw subtle background grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, height * 0.25),
      Offset(width, height * 0.25),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, height * 0.5),
      Offset(width, height * 0.5),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, height * 0.75),
      Offset(width, height * 0.75),
      gridPaint,
    );

    // 2. Draw 32 FFT Frequency Bars
    final barCount = fftValues.length;
    const barSpacing = 2.0;
    final barWidth = (width - (barCount - 1) * barSpacing) / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final mag = isPlaying ? fftValues[i].clamp(0.02, 1.0) : 0.02;
      final barHeight = mag * (height - 6);
      final y = height - barHeight;

      // Color transition: Bass (Cyan/Blue) -> Mid (Amber/Orange) -> High (Rose/Magenta)
      final norm = i / barCount;
      final barColor = norm < 0.35
          ? Color.lerp(
              const Color(0xFF06B6D4),
              const Color(0xFF3B82F6),
              norm / 0.35,
            )!
          : norm < 0.7
          ? Color.lerp(
              const Color(0xFFF59E0B),
              const Color(0xFFEC4899),
              (norm - 0.35) / 0.35,
            )!
          : Color.lerp(
              const Color(0xFFEC4899),
              const Color(0xFFF43F5E),
              (norm - 0.7) / 0.3,
            )!;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [barColor.withAlpha(120), barColor],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);

      // Draw Peak Cap
      if (isPlaying) {
        final peakMag = peakCaps[i].clamp(0.0, 1.0);
        final peakY = height - (peakMag * (height - 6)) - 2;
        final capPaint = Paint()
          ..color = Colors.white.withAlpha(220)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, peakY, barWidth, 2),
            const Radius.circular(1),
          ),
          capPaint,
        );
      }
    }

    // 3. Draw Oscilloscope Waveform overlay across center
    if (isPlaying && waveform.isNotEmpty) {
      final wavePath = Path();
      final waveStep = width / (waveform.length - 1);
      final centerY = height * 0.5;

      for (var i = 0; i < waveform.length; i++) {
        final x = i * waveStep;
        final y = centerY - (waveform[i] * (height * 0.42));
        if (i == 0) {
          wavePath.moveTo(x, y);
        } else {
          wavePath.lineTo(x, y);
        }
      }

      final waveGlowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(wavePath, waveGlowPaint);

      final waveLinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(wavePath, waveLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DjVisualizerPainter oldDelegate) {
    return isPlaying || oldDelegate.isPlaying != isPlaying;
  }
}
