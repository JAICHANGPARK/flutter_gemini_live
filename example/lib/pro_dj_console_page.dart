import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'dj_midi_box_page.dart';
import 'foldable_utils.dart';
import 'soloud_live_audio_player.dart';
import 'scrollable_app_bar_actions.dart';

/// Professional DJ Console for Google Gemini Live (Lyria RealTime)
/// streaming music generation.
class ProDjConsolePage extends StatefulWidget {
  const ProDjConsolePage({super.key});

  @override
  State<ProDjConsolePage> createState() => _ProDjConsolePageState();
}

class _ProDjConsolePageState extends State<ProDjConsolePage>
    with TickerProviderStateMixin {
  // Session & Audio Player
  LiveMusicSession? _session;
  late final SoloudLiveAudioPlayer _audioPlayer;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPlaying = false;

  // Deck A & Deck B Prompts
  String _deckAPrompt =
      'Minimal techno with deep 909 kick and atmospheric synths';
  String _deckBPrompt = 'Acid 303 bassline with shimmering percussion';
  double _deckAWeight = 1.0;
  double _deckBWeight = 0.5;

  // Crossfader: 0.0 (Deck A 100%) <---> 1.0 (Deck B 100%)
  double _crossfader = 0.5;

  // DJM Mixer Controls
  int _bpm = 128;
  int? _lastAppliedBpm;
  Scale? _selectedScale = Scale.D_MAJOR_B_MINOR;
  Scale? _lastAppliedScale;
  MusicGenerationMode _mode = MusicGenerationMode.QUALITY;

  double _temperature = 1.1; // Trim / Variance
  double _brightness = 0.5; // HI EQ
  double _density = 0.5; // MID EQ
  double _guidance = 4.0; // LOW EQ (1.0 to 6.0)

  // Stem Isolators (Kill Switches)
  bool _muteBass = false;
  bool _muteDrums = false;
  bool _onlyBassAndDrums = false;
  final bool _autoResetOnTempoScaleChange = true;

  // Real-time audio metering & Jog wheel rotation
  late final AnimationController _jogAnimController;
  double _currentRmsL = 0.0;
  double _currentRmsR = 0.0;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Active Hot Cue Pad
  int _activePadIndex = 0;

  // Diagnostics log
  final List<String> _consoleLogs = [];

  // Hot Cue Pad Presets
  final List<_HotCuePadData> _hotCuePads = [
    _HotCuePadData(
      label: '909 TECHNO',
      color: Colors.cyanAccent,
      promptA:
          'Peak-time Berlin techno with pounding 909 kick and dark warehouse ambiance',
      promptB:
          'Hypnotic modular synth arpeggios and industrial metallic percussion',
      bpm: 130,
      scale: Scale.C_MAJOR_A_MINOR,
      mode: MusicGenerationMode.QUALITY,
    ),
    _HotCuePadData(
      label: 'ACID 303',
      color: const Color(0xFF76FF03),
      promptA: 'Resonant TB-303 acid bassline with screaming filter sweeps',
      promptB: 'Crisp electro breakbeats and analogue clap sequences',
      bpm: 126,
      scale: Scale.D_MAJOR_B_MINOR,
      mode: MusicGenerationMode.QUALITY,
    ),
    _HotCuePadData(
      label: 'LO-FI STUDY',
      color: Colors.amberAccent,
      promptA: 'Mellow lo-fi hip hop beat with dusty vinyl crackle',
      promptB:
          'Warm Fender Rhodes electric piano chords and acoustic upright bass',
      bpm: 84,
      scale: Scale.C_MAJOR_A_MINOR,
      mode: MusicGenerationMode.QUALITY,
    ),
    _HotCuePadData(
      label: 'AFROBEAT',
      color: Colors.orangeAccent,
      promptA:
          'Uplifting Afrobeat groove with brass horn section and talking drums',
      promptB: 'Funky rhythmic rhythm guitar and polyrhythmic percussion',
      bpm: 116,
      scale: Scale.G_MAJOR_E_MINOR,
      mode: MusicGenerationMode.QUALITY,
    ),
    _HotCuePadData(
      label: 'CYBERPUNK',
      color: Colors.purpleAccent,
      promptA: 'Dark cinematic cyberpunk synthwave with heavy distorted bass',
      promptB: 'Retro neon 80s lead synths and gated snare drums',
      bpm: 110,
      scale: Scale.D_MAJOR_B_MINOR,
      mode: MusicGenerationMode.QUALITY,
    ),
    _HotCuePadData(
      label: 'AMBIENT DRONE',
      color: Colors.lightBlueAccent,
      promptA: 'Deep ethereal ambient synth drone with infinite reverberation',
      promptB: 'Subtle crystal piano drops and atmospheric string textures',
      bpm: 70,
      scale: Scale.F_MAJOR_D_MINOR,
      mode: MusicGenerationMode.DIVERSITY,
    ),
    _HotCuePadData(
      label: 'VOCAL CHOPS',
      color: Colors.pinkAccent,
      promptA: 'Euphoric melodic progressive house with vocal chops and piano',
      promptB: 'Soulful human voice hums and choral vocalization layers',
      bpm: 124,
      scale: Scale.A_MAJOR_G_FLAT_MINOR,
      mode: MusicGenerationMode.VOCALIZATION,
    ),
    _HotCuePadData(
      label: 'DROP & RESET',
      color: Colors.redAccent,
      promptA:
          'Massive festival EDM drop with driving synth leads and heavy sub',
      promptB: 'Punchy snare roll build-up into explosive bass drop',
      bpm: 128,
      scale: Scale.D_MAJOR_B_MINOR,
      mode: MusicGenerationMode.QUALITY,
      isHardDrop: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
    _audioPlayer.init();

    _jogAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPlaying && mounted) {
        setState(() {
          _elapsed += const Duration(milliseconds: 100);
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _jogAnimController.dispose();
    _session?.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _log(String msg) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.insert(
        0,
        '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg',
      );
      if (_consoleLogs.length > 50) _consoleLogs.removeLast();
    });
  }

  // ==========================================================================
  // Connection & Streaming
  // ==========================================================================

  Future<void> _connect() async {
    if (!ApiKeyStore.hasApiKey) {
      final changed = await AppSettingsDialog.show(context);
      if (changed != true || !ApiKeyStore.hasApiKey) return;
    }

    setState(() => _isConnecting = true);
    _log('Connecting to Google Gemini Lyria RealTime WebSocket...');

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
              _log('🟢 Deck WebSocket connection established');
            },
            onMessage: (message) {
              _onMessage(message);
            },
            onError: (err, st) {
              _log('⚠️ Stream error: $err');
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isPlaying = false;
                });
              }
            },
            onClose: (code, reason) {
              _log('🔴 Connection closed: $code ($reason)');
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isPlaying = false;
                });
                _jogAnimController.stop();
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
      _log('Connected to Lyria RealTime! Initializing DJ Decks...');

      // Apply initial setup
      _sendWeightedPrompts();
      _sendGenerationConfig();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎧 Pro DJ Console Connected to Lyria RealTime!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _log('Connection failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMessage(LiveMusicServerMessage message) {
    final chunk = message.audioChunk;
    if (chunk != null && chunk.data != null) {
      final bytes = chunk.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        // Discard in-flight server chunks if user paused or stopped
        if (!_isPlaying) return;

        _audioPlayer.appendPcmBytes(bytes);

        // Calculate RMS for DJ VU meters & Jog display
        final rms = GeminiLiveAudioUtils.calculateRms(bytes);
        final visualScale = GeminiLiveAudioUtils.toVisualScale(
          rms,
          factor: 2.2,
        );

        final randSkew = (math.Random().nextDouble() - 0.5) * 0.15;
        if (mounted) {
          setState(() {
            _currentRmsL = visualScale.clamp(0.0, 1.0);
            _currentRmsR = (visualScale + randSkew).clamp(0.0, 1.0);
          });
        }
      }
    }
  }

  Future<void> _play() async {
    if (_session == null) return;
    _log('▶ [PLAY] Starting music playback stream...');
    _session!.play();
    setState(() => _isPlaying = true);
    _jogAnimController.repeat();
  }

  Future<void> _pause() async {
    if (_session == null) return;
    _log('⏸ [PAUSE] Pausing stream playback...');
    _session!.pause();
    _audioPlayer.clear();
    setState(() {
      _isPlaying = false;
      _currentRmsL = 0.0;
      _currentRmsR = 0.0;
    });
    _jogAnimController.stop();
  }

  Future<void> _stop() async {
    if (_session == null) return;
    _log('⏹ [CUE/STOP] Stopping stream...');
    _session!.stop();
    _audioPlayer.clear();
    setState(() {
      _isPlaying = false;
      _currentRmsL = 0.0;
      _currentRmsR = 0.0;
    });
    _jogAnimController.stop();
  }

  Future<void> _resetContext() async {
    if (_session == null) return;
    _log('🔥 [HARD DROP / RESET CONTEXT] Executing instant context reset...');
    _session!.resetContext();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Instant Beat Drop: Context reset executed!'),
        backgroundColor: Colors.purple,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _sendWeightedPrompts() {
    if (_session == null) return;

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

    _session!.setWeightedPrompts(prompts);
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

    _session!.setMusicGenerationConfig(config);

    final bpmOrScaleChanged =
        (_lastAppliedBpm != null && _bpm != _lastAppliedBpm) ||
        (_lastAppliedScale != _selectedScale);
    _lastAppliedBpm = _bpm;
    _lastAppliedScale = _selectedScale;

    if (bpmOrScaleChanged && _autoResetOnTempoScaleChange) {
      _session!.resetContext();
      _log('🔄 Auto-reset context on Tempo ($_bpm BPM) / Scale transition');
    }
  }

  void _applyHotCuePad(int index) {
    final pad = _hotCuePads[index];
    setState(() {
      _activePadIndex = index;
      _deckAPrompt = pad.promptA;
      _deckBPrompt = pad.promptB;
      _bpm = pad.bpm;
      _selectedScale = pad.scale;
      _mode = pad.mode;
    });

    if (_isConnected) {
      _sendWeightedPrompts();
      _sendGenerationConfig();
      if (pad.isHardDrop) {
        _resetContext();
      }
    }

    _log(
      '🎛️ Hot Cue Pad [${pad.label}] Triggered (${pad.bpm} BPM, ${pad.mode.name})',
    );
  }

  // ==========================================================================
  // Build UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRO DJ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
              'DIGITAL MULTI-PLAYER CONSOLE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            ),
          ],
        ),
        actions: [
          ScrollableAppBarActions(
            children: [
              // ON AIR Glowing LED Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? Colors.redAccent.withAlpha(50)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isPlaying ? Colors.redAccent : Colors.white24,
                    width: 1.5,
                  ),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withAlpha(150),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _isPlaying ? Colors.redAccent : Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ON AIR',
                      style: TextStyle(
                        color: _isPlaying ? Colors.redAccent : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFFA855F7),
                ),
                tooltip: 'DJ MIDI Box (16-Pad Rotary Grid)',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DjMidiBoxPage()),
                  );
                },
              ),
              const LanguageSelectorButton(compact: true),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () => AppSettingsDialog.show(context),
                tooltip: 'Settings',
              ),
              Builder(
                builder: (context) {
                  final foldableInfo = FoldableLayoutInfo.of(context);
                  if (!foldableInfo.hasHinge &&
                      !foldableInfo.isFoldableOrWide) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, left: 2),
                    child: Tooltip(
                      message: foldableInfo.isTabletop
                          ? 'Tabletop / Flex Mode'
                          : (foldableInfo.isDualScreen
                                ? 'Duo Dual-Screen Active'
                                : 'Foldable Active'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              foldableInfo.isTabletop
                                  ? Icons.laptop_chromebook_rounded
                                  : Icons.devices_fold_rounded,
                              size: 13,
                              color: Colors.cyanAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              foldableInfo.isTabletop
                                  ? 'FLEX DJ'
                                  : (foldableInfo.isDualScreen
                                        ? 'DUO DJ'
                                        : 'FOLD DJ'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final foldableInfo = FoldableLayoutInfo.of(context);

            // 1. Tabletop / Flex Mode (Galaxy Z Fold half-folded at 90° on a desk)
            if (foldableInfo.isTabletop) {
              return Column(
                children: [
                  // Top Screen (Upright Master LCD Display & Diagnostics)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: Column(
                        children: [
                          _buildMasterLcdDisplay(),
                          const SizedBox(height: 6),
                          Expanded(child: _buildConsoleLogs()),
                        ],
                      ),
                    ),
                  ),

                  // Physical Fold Line / Crease Divider
                  Container(height: 4, color: const Color(0xFF1E2638)),

                  // Bottom Screen (Tactile DJ Console flat on desk)
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                      child: Column(
                        children: [
                          _buildHardwareConsoleBody(
                            isWide: constraints.maxWidth >= 600,
                          ),
                          const SizedBox(height: 10),
                          _buildPerformancePadsSection(),
                          const SizedBox(height: 10),
                          _buildMasterTransportBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // 2. Dual-Screen Book Mode (Surface Duo / 2 physical screens)
            if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Screen: Master LCD + CDJ Deck A + Pads
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          _buildMasterLcdDisplay(),
                          const SizedBox(height: 12),
                          _buildCdjDeck(isDeckA: true),
                          const SizedBox(height: 12),
                          _buildPerformancePadsSection(),
                        ],
                      ),
                    ),
                  ),

                  // Center Hinge Spacer (Avoids physical hinge gap)
                  SizedBox(
                    width: (foldableInfo.hingeBounds?.width ?? 16).clamp(
                      8.0,
                      36.0,
                    ),
                    child: Center(
                      child: Container(width: 2, color: Colors.white24),
                    ),
                  ),

                  // Right Screen: DJM Mixer + CDJ Deck B + Transport + Logs
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          _buildDjmCenterMixer(),
                          const SizedBox(height: 12),
                          _buildCdjDeck(isDeckA: false),
                          const SizedBox(height: 12),
                          _buildMasterTransportBar(),
                          const SizedBox(height: 12),
                          _buildConsoleLogs(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // 3. Standard & Foldable Wide (Galaxy Z Fold unfolded or tablet/desktop)
            final isWide =
                constraints.maxWidth >= 720 || foldableInfo.isFoldableOrWide;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMasterLcdDisplay(),
                  const SizedBox(height: 14),
                  _buildHardwareConsoleBody(isWide: isWide),
                  const SizedBox(height: 14),
                  _buildPerformancePadsSection(),
                  const SizedBox(height: 14),
                  _buildMasterTransportBar(),
                  const SizedBox(height: 14),
                  _buildConsoleLogs(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHardwareConsoleBody({required bool isWide}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: CDJ Deck A
          Expanded(flex: 5, child: _buildCdjDeck(isDeckA: true)),
          const SizedBox(width: 12),
          // Center: DJM Mixer Section
          Expanded(flex: 4, child: _buildDjmCenterMixer()),
          const SizedBox(width: 12),
          // Right: CDJ Deck B
          Expanded(flex: 5, child: _buildCdjDeck(isDeckA: false)),
        ],
      );
    } else {
      // Mobile / Narrow Stack Layout
      return Column(
        children: [
          _buildCdjDeck(isDeckA: true),
          const SizedBox(height: 12),
          _buildDjmCenterMixer(),
          const SizedBox(height: 12),
          _buildCdjDeck(isDeckA: false),
        ],
      );
    }
  }

  // ==========================================================================
  // 1. CDJ Master LCD Display Header
  // ==========================================================================

  Widget _buildMasterLcdDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2638), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Elapsed Time Readout
              Row(
                children: [
                  const Text(
                    'TIME  ',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),

              // Real-time BPM display
              Row(
                children: [
                  const Text(
                    'BPM  ',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$_bpm.0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              // Harmonic Key / Scale
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A273A),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: Color(0xFF00E5FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedScale != null ? _selectedScale!.name : 'NO KEY',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Engine Connection Pill
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: _isConnected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isConnected ? 'LYRIA REALTIME ONLINE' : 'STANDBY',
                    style: TextStyle(
                      color: _isConnected
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Multi-wave Beat Grid Display
          SizedBox(
            height: 38,
            child: Row(
              children: List.generate(48, (index) {
                final heightFactor = _isPlaying
                    ? 0.2 +
                          math
                                  .sin(
                                    (index + _elapsed.inMilliseconds / 80) *
                                        0.4,
                                  )
                                  .abs() *
                              0.7 *
                              _currentRmsL
                    : 0.15;
                final isBeatMarker = index % 4 == 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    alignment: Alignment.center,
                    child: Container(
                      height: 36 * heightFactor.clamp(0.1, 1.0),
                      decoration: BoxDecoration(
                        color: isBeatMarker
                            ? const Color(0xFF00E5FF)
                            : (index % 2 == 0
                                  ? const Color(0xFF304FFE)
                                  : const Color(0xFF651FFF)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. CDJ Deck Widget (Deck A or Deck B)
  // ==========================================================================

  Widget _buildCdjDeck({required bool isDeckA}) {
    final deckColor = isDeckA
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFF9100);
    final deckTitle = isDeckA ? 'DECK 1 (A)' : 'DECK 2 (B)';
    final promptText = isDeckA ? _deckAPrompt : _deckBPrompt;
    final promptWeight = isDeckA ? _deckAWeight : _deckBWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262E3E), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck Header & Vinyl Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: deckColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: deckColor.withAlpha(180),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    deckTitle,
                    style: TextStyle(
                      color: deckColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'VINYL MODE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Steerable Prompt Text Editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1D222E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: deckColor.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEERABLE PROMPT',
                      style: TextStyle(
                        color: deckColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'WEIGHT: ${promptWeight.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  promptText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: deckColor,
                        ),
                        child: Slider(
                          value: promptWeight,
                          min: 0.1,
                          max: 1.0,
                          onChanged: (val) {
                            setState(() {
                              if (isDeckA) {
                                _deckAWeight = val;
                              } else {
                                _deckBWeight = val;
                              }
                            });
                            _sendWeightedPrompts();
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white70,
                      ),
                      onPressed: () => _showEditPromptDialog(isDeckA),
                      tooltip: 'Edit Prompt',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CDJ Style Jog Wheel
          Center(
            child: _DjJogWheel(
              anim: _jogAnimController,
              isPlaying: _isPlaying,
              deckColor: deckColor,
              rms: isDeckA ? _currentRmsL : _currentRmsR,
              bpm: _bpm,
              onTap: () {
                if (_isConnected) {
                  _resetContext();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Deck Transport (CUE / PLAY)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRoundTransportButton(
                label: 'CUE',
                color: Colors.amber,
                onPressed: _isConnected ? _pause : null,
              ),
              _buildRoundTransportButton(
                label: 'PLAY',
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.greenAccent,
                onPressed: _isConnected ? (_isPlaying ? _pause : _play) : null,
              ),
              _buildRoundTransportButton(
                label: 'SYNC',
                color: Colors.blueAccent,
                onPressed: () {
                  setState(() {
                    if (isDeckA) {
                      _deckAWeight = 1.0;
                    } else {
                      _deckBWeight = 1.0;
                    }
                  });
                  _sendWeightedPrompts();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. DJM Center Mixer Section (4-Band EQ, VU Meters, Crossfader)
  // ==========================================================================

  Widget _buildDjmCenterMixer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232A38), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mixer Top Silk Screen Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4-CH DIGITAL MIXER',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withAlpha(120),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _mode.name,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Band Rotary Knobs + TRIM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRotaryKnob(
                label: 'TRIM (TEMP)',
                value: _temperature,
                min: 0.0,
                max: 2.5,
                color: Colors.purpleAccent,
                onChanged: (v) {
                  setState(() => _temperature = v);
                  _sendGenerationConfig();
                },
              ),
              _buildRotaryKnob(
                label: 'HI (BRIGHT)',
                value: _brightness,
                min: 0.0,
                max: 1.0,
                color: Colors.blueAccent,
                onChanged: (v) {
                  setState(() => _brightness = v);
                  _sendGenerationConfig();
                },
              ),
              _buildRotaryKnob(
                label: 'MID (DENSE)',
                value: _density,
                min: 0.0,
                max: 1.0,
                color: Colors.orangeAccent,
                onChanged: (v) {
                  setState(() => _density = v);
                  _sendGenerationConfig();
                },
              ),
              _buildRotaryKnob(
                label: 'LOW (GUIDE)',
                value: _guidance,
                min: 1.0,
                max: 6.0,
                color: Colors.cyanAccent,
                onChanged: (v) {
                  setState(() => _guidance = v);
                  _sendGenerationConfig();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Stereo VU Meters + Stem Isolator Switches
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left VU Meter (CH 1)
              _DjVuMeter(level: _currentRmsL, channelLabel: 'CH 1'),
              const SizedBox(width: 14),

              // Stem Isolator / Kill Buttons
              Column(
                children: [
                  _buildStemKillButton('BASS KILL', _muteBass, (val) {
                    setState(() => _muteBass = val);
                    _sendGenerationConfig();
                  }),
                  const SizedBox(height: 8),
                  _buildStemKillButton('DRUM KILL', _muteDrums, (val) {
                    setState(() => _muteDrums = val);
                    _sendGenerationConfig();
                  }),
                  const SizedBox(height: 8),
                  _buildStemKillButton('ONLY BASS/DRUM', _onlyBassAndDrums, (
                    val,
                  ) {
                    setState(() => _onlyBassAndDrums = val);
                    _sendGenerationConfig();
                  }),
                ],
              ),
              const SizedBox(width: 14),

              // Right VU Meter (CH 2)
              _DjVuMeter(level: _currentRmsR, channelLabel: 'CH 2'),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Master Crossfader (A <---> B)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C3446)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CROSSFADER [A]',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'A: ${(1.0 - _crossfader).toStringAsFixed(2)}  |  B: ${_crossfader.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      '[B] CROSSFADER',
                      style: TextStyle(
                        color: Color(0xFFFF9100),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: const Color(0xFFFF9100),
                    inactiveTrackColor: const Color(0xFF00E5FF),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: _crossfader,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => _crossfader = val);
                      _sendWeightedPrompts();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. Performance Pads Section (8 RGB Silicone Pads)
  // ==========================================================================

  Widget _buildPerformancePadsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252D3C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOT CUE / SOUND BANK (8-PAD RUBBER PERFORMANCE)',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'RGB VELOCITY BACKLIT',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _hotCuePads.length,
            itemBuilder: (context, index) {
              final pad = _hotCuePads[index];
              final isActive = _activePadIndex == index;
              return InkWell(
                onTap: () => _applyHotCuePad(index),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isActive
                        ? pad.color.withAlpha(80)
                        : const Color(0xFF1C222E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? pad.color : pad.color.withAlpha(80),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: pad.color.withAlpha(140),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pad.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? Colors.white : pad.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${pad.bpm} BPM',
                        style: TextStyle(
                          color: isActive ? Colors.white70 : Colors.white38,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. Master Transport Bar
  // ==========================================================================

  Widget _buildMasterTransportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF242C3C)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          // Connection Toggle Button
          ElevatedButton.icon(
            onPressed: _isConnecting
                ? null
                : (_isConnected ? () => _session?.close() : _connect),
            icon: Icon(
              _isConnected ? Icons.link_off : Icons.power_settings_new,
              size: 18,
            ),
            label: Text(
              _isConnecting
                  ? 'CONNECTING...'
                  : (_isConnected ? 'DISCONNECT' : 'CONNECT CONSOLE'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isConnected
                  ? Colors.red.shade800
                  : Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          // Master Play / Pause / Drop Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _isConnected ? (_isPlaying ? _pause : _play) : null,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 20,
                ),
                label: Text(_isPlaying ? 'PAUSE' : 'PLAY MASTER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isConnected ? _stop : null,
                icon: const Icon(Icons.stop, size: 20),
                label: const Text('STOP / CUE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isConnected ? _resetContext : null,
                icon: const Icon(Icons.bolt, size: 20),
                label: const Text('HARD DROP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 6. Console System Logs
  // ==========================================================================

  Widget _buildConsoleLogs() {
    return Card(
      color: const Color(0xFF10131A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          '🎛️ DJ CONSOLE DIAGNOSTIC TERMINAL',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            color: Colors.black45,
            child: ListView.builder(
              reverse: true,
              itemCount: _consoleLogs.length,
              itemBuilder: (context, idx) {
                return Text(
                  _consoleLogs[idx],
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Helper Widgets
  // ==========================================================================

  Widget _buildRoundTransportButton({
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2432),
              border: Border.all(
                color: onPressed != null ? color : Colors.white24,
                width: 2.5,
              ),
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: color.withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon ?? Icons.album,
              color: onPressed != null ? color : Colors.white30,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? color : Colors.white30,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRotaryKnob({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final norm = (value - min) / (max - min);
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 100.0;
            final newVal = (value + delta * (max - min)).clamp(min, max);
            onChanged(newVal);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F2533),
              border: Border.all(color: color.withAlpha(120), width: 2),
            ),
            child: Transform.rotate(
              angle: (norm - 0.5) * 4.5,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStemKillButton(
    String label,
    bool isMuted,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!isMuted),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMuted ? Colors.red.shade900 : const Color(0xFF1B2230),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isMuted ? Colors.redAccent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isMuted ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  void _showEditPromptDialog(bool isDeckA) {
    final controller = TextEditingController(
      text: isDeckA ? _deckAPrompt : _deckBPrompt,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B26),
          title: Text(
            isDeckA ? 'Edit Deck 1 (A) Prompt' : 'Edit Deck 2 (B) Prompt',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter musical style, instruments, or vibe...',
              hintStyle: TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Color(0xFF222838),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isDeckA) {
                    _deckAPrompt = controller.text.trim();
                  } else {
                    _deckBPrompt = controller.text.trim();
                  }
                });
                _sendWeightedPrompts();
                Navigator.pop(ctx);
              },
              child: const Text('APPLY'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds.$millis';
  }
}

// ============================================================================
// Animated DJ Jog Wheel
// ============================================================================

class _DjJogWheel extends StatelessWidget {
  final AnimationController anim;
  final bool isPlaying;
  final Color deckColor;
  final double rms;
  final int bpm;
  final VoidCallback onTap;

  const _DjJogWheel({
    required this.anim,
    required this.isPlaying,
    required this.deckColor,
    required this.rms,
    required this.bpm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final rotAngle = anim.value * 2 * math.pi;
          return Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F1218),
              border: Border.all(color: const Color(0xFF2B3344), width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(200),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                if (isPlaying)
                  BoxShadow(
                    color: deckColor.withAlpha(
                      (100 * rms).toInt().clamp(20, 150),
                    ),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Vinyl Grooves
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _VinylGroovesPainter(),
                ),

                // Center LCD Screen
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A0C10),
                    border: Border.all(color: deckColor, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Position Needle
                      Transform.rotate(
                        angle: rotAngle,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 3,
                            height: 14,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.redAccent,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPlaying ? Icons.album : Icons.pause,
                            size: 18,
                            color: deckColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$bpm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2533)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    for (double r = 42; r < 72; r += 5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Stereo LED VU Meter
// ============================================================================

class _DjVuMeter extends StatelessWidget {
  final double level;
  final String channelLabel;

  const _DjVuMeter({required this.level, required this.channelLabel});

  @override
  Widget build(BuildContext context) {
    const totalBars = 10;
    final activeCount = (level * totalBars).round();

    return Column(
      children: [
        Text(
          channelLabel,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 14,
          height: 100,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF202634)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(totalBars, (index) {
              final barIndex = totalBars - 1 - index;
              final isActive = barIndex < activeCount;
              Color color;
              if (barIndex >= 8) {
                color = Colors.redAccent;
              } else if (barIndex >= 6) {
                color = Colors.amberAccent;
              } else {
                color = Colors.greenAccent;
              }

              return Container(
                height: 7,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? color : color.withAlpha(40),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: isActive
                      ? [BoxShadow(color: color.withAlpha(180), blurRadius: 3)]
                      : null,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _HotCuePadData {
  final String label;
  final Color color;
  final String promptA;
  final String promptB;
  final int bpm;
  final Scale? scale;
  final MusicGenerationMode mode;
  final bool isHardDrop;

  const _HotCuePadData({
    required this.label,
    required this.color,
    required this.promptA,
    required this.promptB,
    required this.bpm,
    this.scale,
    required this.mode,
    this.isHardDrop = false,
  });
}
