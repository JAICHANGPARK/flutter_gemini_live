import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
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

  // Music parameters
  int _bpm = 120;
  final MusicGenerationMode _mode = MusicGenerationMode.QUALITY;
  Scale? _selectedScale;

  // Real-time audio RMS for beat pulse
  double _rmsLevel = 0.0;
  late final AnimationController _pulseAnim;

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
        prompt: 'Bossa Nova acoustic guitar rhythm with gentle shaker and warm bass',
        color: const Color(0xFF38BDF8), // Sky Blue
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Chillwave',
        prompt: 'Nostalgic chillwave synthesizer chords with warm analog tape saturation',
        color: const Color(0xFF818CF8), // Indigo
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Drum and Bass',
        prompt: 'Fast 174 BPM drum and bass rolling breakbeats and reese bassline',
        color: const Color(0xFFFB7185), // Rose
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Post Punk',
        prompt: 'Post punk angular electric guitar riffs with driving drum machine',
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
        prompt: 'Funky slap bass groove with crisp rhythmic rhythm guitar and claps',
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
        prompt: 'Lush orchestral string ensemble crescendo with cinematic emotional depth',
        color: const Color(0xFF34D399), // Mint Green (Active in reference!)
        weight: 0.80,
      ),

      // Row 3
      _MidiKnobData(
        title: 'Sparkling Arpeggios',
        prompt: 'Sparkling crystalline synthesizer arpeggios floating over stereo reverb',
        color: const Color(0xFF22D3EE), // Cyan
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Staccato Rhythms',
        prompt: 'Tight staccato pizzicato rhythms and percussive melodic accents',
        color: const Color(0xFFF97316), // Orange
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Punchy Kick',
        prompt: 'Punchy deep 4/4 electronic dance kick drum with chest-thumping low end',
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
        prompt: 'Catchy modern energetic K-Pop upbeat synth hook and polished drum production',
        color: const Color(0xFFEC4899), // Hot Pink
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Neo Soul',
        prompt: 'Warm neo soul Fender Rhodes electric piano chords with laid-back swing beat',
        color: const Color(0xFFF59E0B), // Warm Gold
        weight: 0.0,
      ),
      _MidiKnobData(
        title: 'Trip Hop',
        prompt: 'Moody Bristol trip hop downtempo vinyl beat with dusty acoustic jazz bass',
        color: const Color(0xFF6366F1), // Royal Purple-Blue (Active in reference!)
        weight: 0.70,
      ),
      _MidiKnobData(
        title: 'Thrash',
        prompt: 'Aggressive fast thrash metal double-bass drumming and distorted heavy riffs',
        color: const Color(0xFFDC2626), // Crimson
        weight: 0.0,
      ),
    ];
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _session?.close();
    _audioPlayer.dispose();
    super.dispose();
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
            },
            onMessage: (message) {
              _handleServerMessage(message);
            },
            onError: (err, st) {
              debugPrint('[MidiBox] Error: $err');
              if (mounted) {
                setState(() {
                  _isConnected = false;
                  _isPlaying = false;
                });
              }
            },
            onClose: (code, reason) {
              debugPrint('[MidiBox] Closed: $code ($reason)');
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
          content: Text('🎛️ DJ MIDI Box Connected to Lyria RealTime! Tap ▶ to Play.'),
          backgroundColor: Colors.deepPurpleAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleServerMessage(LiveMusicServerMessage message) {
    final chunk = message.audioChunk;
    if (chunk != null && chunk.data != null) {
      final bytes = chunk.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        // Drop in-flight chunks if user has paused or stopped playback
        if (!_isPlaying) return;

        _audioPlayer.appendPcmBytes(bytes);

        final rms = GeminiLiveAudioUtils.calculateRms(bytes);
        final visualScale = GeminiLiveAudioUtils.toVisualScale(rms, factor: 2.2);

        if (mounted) {
          setState(() {
            _rmsLevel = visualScale.clamp(0.0, 1.0);
          });
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
    } else {
      _session?.play();
      setState(() => _isPlaying = true);
    }
  }

  void _sendWeightedPrompts() {
    if (_session == null) return;

    // Filter knobs with weight > 0
    final active = _knobs.where((k) => k.weight > 0.01).toList();

    final List<WeightedPrompt> prompts;
    if (active.isEmpty) {
      // Lyria requires at least one prompt
      prompts = [
        WeightedPrompt(
          text: 'Ambient synth pad drone with gentle harmonic undertones',
          weight: 0.1,
        ),
      ];
    } else {
      prompts = active
          .map((k) => WeightedPrompt(text: k.prompt, weight: k.weight))
          .toList();
    }

    _session!.setWeightedPrompts(prompts);
  }

  void _sendGenerationConfig() {
    if (_session == null) return;

    final config = LiveMusicGenerationConfig(
      bpm: _bpm,
      scale: _selectedScale,
      musicGenerationMode: _mode,
      temperature: 1.1,
      guidance: 4.0,
      density: 0.5,
      brightness: 0.5,
    );

    _session!.setMusicGenerationConfig(config);
  }

  void _onKnobChanged(int index, double newWeight) {
    setState(() {
      _knobs[index].weight = newWeight.clamp(0.0, 1.0);
    });
    if (_isConnected) {
      _sendWeightedPrompts();
    }
  }

  void _onKnobTapped(int index) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Knob: ${knob.title}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
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
          child: Column(
            children: [
              // Top Minimal App Bar
              _buildTopHeader(),

              // 4x4 Rotary Knobs Grid
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: _knobs.length,
                        itemBuilder: (context, index) {
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
                  ),
                ),
              ),

              // Bottom Floating Play/Pause Button
              _buildBottomControls(),
            ],
          ),
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
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
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
                    final nextIdx = (currentIdx == -1 ? 3 : currentIdx + 1) % bpms.length;
                    _bpm = bpms[nextIdx];
                  });
                  if (_isConnected) {
                    _sendGenerationConfig();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? const Color(0xFF10B981).withAlpha(40)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isConnected ? const Color(0xFF10B981) : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _isConnected ? const Color(0xFF10B981) : Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnecting
                            ? 'CONNECTING'
                            : (_isConnected ? 'ONLINE' : 'CONNECT'),
                        style: TextStyle(
                          color: _isConnected ? const Color(0xFF10B981) : Colors.white70,
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

              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
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
                colors: [
                  Color(0xFF4C2A85),
                  Color(0xFF2A1550),
                ],
              ),
              border: Border.all(
                color: _isPlaying ? const Color(0xFFA855F7) : Colors.white.withAlpha(40),
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
      ..color = const Color(0xFF0F172A) // Dark slate black
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
