import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'foldable_utils.dart';
import 'live_api_defaults.dart';
import 'scrollable_app_bar_actions.dart';

/// Preset YouTube videos for quick testing.
class YouTubePreset {
  final String title;
  final String subtitle;
  final String videoId;
  final String category;

  const YouTubePreset({
    required this.title,
    required this.subtitle,
    required this.videoId,
    required this.category,
  });
}

const List<YouTubePreset> kYouTubePresets = [
  YouTubePreset(
    title: 'Google Gemini AI 발표',
    subtitle: 'Google 공식: 가장 진보된 멀티모달 Gemini 모델 발표',
    videoId: 'jV1vkHv4zq8',
    category: 'Gemini / AI',
  ),
  YouTubePreset(
    title: 'TED: Demis Hassabis',
    subtitle: 'DeepMind CEO: AI가 과학의 비밀을 푸는 방법 (AlphaFold)',
    videoId: '0_M_syPuFos',
    category: 'Keynote',
  ),
  YouTubePreset(
    title: 'Steve Jobs 스탠포드 연설',
    subtitle: '스탠포드 대학교 2005 전설적인 졸업식 명연설',
    videoId: 'UF8uR6Z6KLc',
    category: 'Speech',
  ),
  YouTubePreset(
    title: 'Flutter in 100 Seconds',
    subtitle: 'Fireship: 100초 만에 완벽 정리하는 Flutter 핵심',
    videoId: 'lHhRhPV--G0',
    category: 'Developer',
  ),
  YouTubePreset(
    title: 'MKBHD Apple Vision Pro',
    subtitle: 'Marques Brownlee의 생생한 공간 컴퓨팅 실사용 리뷰',
    videoId: 'dtp6b76pMak',
    category: 'Tech Review',
  ),
];

/// Supported target languages for subtitle translation.
const List<Map<String, String>> kSubtitleLanguages = [
  {'code': 'ko', 'name': '한국어 (Korean)', 'flag': '🇰🇷'},
  {'code': 'en', 'name': 'English (영어)', 'flag': '🇺🇸'},
  {'code': 'ja', 'name': '日本語 (Japanese)', 'flag': '🇯🇵'},
  {'code': 'zh-Hans', 'name': '简体中文 (Chinese)', 'flag': '🇨🇳'},
  {'code': 'es', 'name': 'Español (Spanish)', 'flag': '🇪🇸'},
  {'code': 'fr', 'name': 'Français (French)', 'flag': '🇫🇷'},
  {'code': 'de', 'name': 'Deutsch (German)', 'flag': '🇩🇪'},
  {'code': 'vi', 'name': 'Tiếng Việt (Vietnamese)', 'flag': '🇻🇳'},
];

/// Subtitle entry in the timeline log.
class SubtitleEntry {
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  SubtitleEntry({
    required this.originalText,
    required this.translatedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String formatTime() {
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class LiveMediaSubtitlePage extends StatefulWidget {
  const LiveMediaSubtitlePage({super.key});

  @override
  State<LiveMediaSubtitlePage> createState() => _LiveMediaSubtitlePageState();
}

class _LiveMediaSubtitlePageState extends State<LiveMediaSubtitlePage>
    with SingleTickerProviderStateMixin {
  static const int _audioSampleRate = 16000;

  final TextEditingController _urlController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  LiveSession? _session;

  // Session state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isAudioStreaming = false;

  // Current Video ID
  String _currentVideoId = 'jV1vkHv4zq8'; // Default: Google Gemini AI

  // Subtitle state
  String _targetLanguageCode = 'ko';
  String _currentOriginalSubtitle = '';
  String _currentTranslatedSubtitle = '';
  final List<SubtitleEntry> _subtitleHistory = [];

  // Audio level meter
  double _audioVolume = 0.0;
  InputDevice? _selectedAudioDevice;
  List<InputDevice> _availableAudioDevices = [];

  // Floating HUD settings (Default to false so subtitles focus in timeline)
  bool _showFloatingHud = false;
  bool _showOriginalText = true;
  double _subtitleFontSize = 18.0;

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: 'gemini-3.5-live-translate-preview',
  );

  // Responsive view tab (0: Video & Controls, 1: Subtitle Transcript)
  int _activeViewTab = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://www.youtube.com/watch?v=$_currentVideoId';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadAudioDevices();
  }

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      if (mounted) {
        setState(() {
          _availableAudioDevices = devices;
          final savedId = ApiKeyStore.audioDeviceId;
          if (savedId.isNotEmpty) {
            _selectedAudioDevice = devices
                .where((d) => d.id == savedId)
                .firstOrNull;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _switchAudioDevice(InputDevice? device) async {
    if (_selectedAudioDevice?.id == device?.id) return;
    setState(() {
      _selectedAudioDevice = device;
    });
    await ApiKeyStore.saveAudioDevice(device?.id ?? '', device?.label ?? '');

    if (_isAudioStreaming) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      _isAudioStreaming = false;
      if (mounted) {
        await _startAudioStreaming();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _session?.close();
    _urlController.dispose();
    _logScrollController.dispose();
    _usageTracker.dispose();
    super.dispose();
  }

  String _extractYouTubeId(String input) {
    final trimmed = input.trim();
    if (trimmed.length == 11 && !trimmed.contains('/')) {
      return trimmed;
    }
    // Match watch?v=ID or youtu.be/ID or embed/ID
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1) ?? trimmed;
  }

  void _loadVideoFromInput() {
    final id = _extractYouTubeId(_urlController.text);
    if (id.isNotEmpty && id.length == 11) {
      setState(() {
        _currentVideoId = id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('YouTube 영상이 로드되었습니다: $id'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 YouTube URL 또는 11자리 비디오 ID를 입력하세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _selectPreset(YouTubePreset preset) {
    setState(() {
      _currentVideoId = preset.videoId;
      _urlController.text = 'https://www.youtube.com/watch?v=${preset.videoId}';
    });
  }

  Future<void> _playVideo() async {
    final url = 'https://www.youtube.com/watch?v=$_currentVideoId';
    if (!kIsWeb) {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'YouTube 영상을 브라우저에서 재생합니다: $url\nBlackHole을 통해 오디오가 실시간 자막으로 번역됩니다.',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.indigo.shade800,
        ),
      );
      if (!_isConnected && !_isConnecting) {
        await _connect();
      }
    }
  }

  String _getTargetLanguageName() {
    final lang = kSubtitleLanguages.firstWhere(
      (e) => e['code'] == _targetLanguageCode,
      orElse: () => {'name': '한국어 (Korean)'},
    );
    return lang['name'] ?? 'Korean';
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      await _disconnect();
    } else {
      await _connect();
    }
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await AppSettingsDialog.show(context);
      if (configured != true || !ApiKeyStore.hasApiKey) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gemini API 키가 설정되지 않았습니다.')),
          );
        }
        return;
      }
    }

    setState(() => _isConnecting = true);

    try {
      final genAI = GoogleGenAI(
        apiKey: ApiKeyStore.apiKey,
        logger: (msg) => debugPrint('[GeminiLive Subtitle] $msg'),
      );

      // Dedicated continuous stream translation model: gemini-3.5-live-translate-preview
      const translationModel = 'gemini-3.5-live-translate-preview';

      final session = await genAI.live.connect(
        LiveConnectParameters(
          model: translationModel,
          config: GenerationConfig(
            responseModalities: const [Modality.AUDIO],
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(
                  voiceName: ApiKeyStore.voice,
                ),
              ),
            ),
            translationConfig: TranslationConfig(
              targetLanguageCode: _targetLanguageCode,
              echoTargetLanguage: true,
            ),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              debugPrint('[GeminiLive Subtitle] 🌐 onOpen received');
            },
            onMessage: (message) {
              if (!mounted) return;
              _handleLiveMessage(message);
            },
            onError: (err, _) {
              debugPrint('[GeminiLive Subtitle] ❌ onError: $err');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Live API 오류: $err')));
            },
            onClose: (code, reason) {
              debugPrint(
                '[GeminiLive Subtitle] 🔒 onClose (code: $code, reason: $reason)',
              );
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                _isAudioStreaming = false;
              });
              if (reason != null && reason.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Live 연결 종료 ($code): $reason')),
                );
              }
            },
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _session = session;
          _isConnected = true;
          _isConnecting = false;
        });
        await _startAudioStreaming();
      }
    } catch (e) {
      debugPrint('[GeminiLive Subtitle] 🚨 Connection failed: $e');
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연결 실패: $e')));
      }
    }
  }

  void _handleLiveMessage(LiveServerMessage message) {
    bool stateChanged = false;

    // Record real-time token usage and cost metrics
    _usageTracker.recordMessage(message);

    // 1. Process original input transcription (STT of speaker speech)
    final inputTranscript =
        message.serverContent?.interimInputTranscription?.text ??
        message.serverContent?.inputTranscription?.text;
    if (inputTranscript != null && inputTranscript.isNotEmpty) {
      if (_currentOriginalSubtitle.isEmpty) {
        _currentOriginalSubtitle = inputTranscript.trimLeft();
      } else {
        if (!_currentOriginalSubtitle.endsWith(' ') &&
            !inputTranscript.startsWith(' ')) {
          _currentOriginalSubtitle += ' ';
        }
        _currentOriginalSubtitle += inputTranscript;
      }
      stateChanged = true;
    }

    // 2. Process translated text from Gemini Live Translate
    final translatedChunk = visibleModelText(message);
    if (translatedChunk != null && translatedChunk.isNotEmpty) {
      if (_currentTranslatedSubtitle.isEmpty) {
        _currentTranslatedSubtitle = translatedChunk.trimLeft();
      } else {
        _currentTranslatedSubtitle += translatedChunk;
      }
      stateChanged = true;
    }

    // 3. Segment sentence or check completion
    final translatedTrimmed = _currentTranslatedSubtitle.trim();
    final bool hasSentenceEnd =
        RegExp(r'[.!?\n]$').hasMatch(translatedTrimmed) ||
        (translatedTrimmed.length > 55 &&
            (translatedTrimmed.endsWith(',') ||
                translatedTrimmed.endsWith(' ')));
    final bool isTurnComplete =
        message.serverContent?.turnComplete == true ||
        message.serverContent?.interactionStatus == InteractionStatus.IDLE;

    if ((hasSentenceEnd || (isTurnComplete && translatedTrimmed.isNotEmpty)) &&
        translatedTrimmed.isNotEmpty) {
      _subtitleHistory.add(
        SubtitleEntry(
          originalText: _currentOriginalSubtitle.trim().isEmpty
              ? '(음성 발화)'
              : _currentOriginalSubtitle.trim(),
          translatedText: translatedTrimmed,
        ),
      );

      _currentOriginalSubtitle = '';
      _currentTranslatedSubtitle = '';
      stateChanged = true;

      // Auto-scroll timeline log
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    if (stateChanged && mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _startAudioStreaming() async {
    if (_isAudioStreaming) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('마이크/오디오 캡처 권한이 필요합니다.')));
      }
      return;
    }

    try {
      final bool enableVoiceProc =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

      final stream = await _audioRecorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _audioSampleRate,
          numChannels: 1,
          device: _selectedAudioDevice,
          autoGain: enableVoiceProc,
          echoCancel: enableVoiceProc,
          noiseSuppress: enableVoiceProc,
          streamBufferSize: 2048,
        ),
      );

      setState(() => _isAudioStreaming = true);

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isAudioStreaming || _session == null || !_isConnected) return;

        // Calculate audio peak for volume VU meter
        if (chunk.length >= 2) {
          final byteData = ByteData.sublistView(chunk);
          var peak = 0;
          for (var i = 0; i < chunk.length - 1; i += 2) {
            final sample = byteData.getInt16(i, Endian.little).abs();
            if (sample > peak) peak = sample;
          }
          final norm = (peak / 32768.0).clamp(0.0, 1.0);
          if (mounted) {
            setState(() {
              _audioVolume = (_audioVolume * 0.3) + (norm * 0.7);
            });
          }
        }

        // Send 16kHz PCM blob to Gemini Live
        final blob = Blob(
          mimeType: 'audio/pcm;rate=$_audioSampleRate',
          data: base64Encode(chunk),
        );
        _session!.sendRealtimeInput(audio: blob);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오디오 스트리밍 시작 오류: $e')));
      }
    }
  }

  Future<void> _disconnect() async {
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _audioRecorder.stop();
    _session?.close();
    _session = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _isAudioStreaming = false;
        _audioVolume = 0.0;
      });
    }
  }

  void _copySubtitlesToClipboard() {
    if (_subtitleHistory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복사할 자막 기록이 없습니다.')));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('=== Gemini Live Translate 실시간 자막 기록 ===');
    for (final item in _subtitleHistory) {
      buffer.writeln('[${item.formatTime()}]');
      if (item.originalText.isNotEmpty) {
        buffer.writeln('원문: ${item.originalText}');
      }
      buffer.writeln('번역: ${item.translatedText}');
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('전체 자막이 클립보드에 복사되었습니다.')));
  }

  void _clearSubtitles() {
    setState(() {
      _subtitleHistory.clear();
      _currentOriginalSubtitle = '';
      _currentTranslatedSubtitle = '';
      _usageTracker.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              : Colors.cyanAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: foldableInfo.isTabletop
                ? Colors.deepOrangeAccent
                : Colors.cyanAccent,
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
                  : Colors.cyanAccent,
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
                    : Colors.cyanAccent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subtitles_rounded, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live Media Subtitles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          ScrollableAppBarActions(
            children: [
              foldablePill(),
              // Target Language Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _targetLanguageCode,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.cyanAccent,
                    ),
                    items: kSubtitleLanguages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang['code'],
                        child: Text('${lang['flag']} ${lang['name']}'),
                      );
                    }).toList(),
                    onChanged: _isConnected
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _targetLanguageCode = val);
                            }
                          },
                  ),
                ),
              ),
              // Real-time token usage and cost badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GeminiLiveUsageBadge(tracker: _usageTracker),
              ),
              _buildAudioDeviceSelectorButton(isCompact: true),
              IconButton(
                icon: const Icon(Icons.copy_all_rounded),
                tooltip: '자막 전체 복사',
                onPressed: _copySubtitlesToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: '자막 초기화',
                onPressed: _clearSubtitles,
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Tabletop / Flex mode: Top screen video player, bottom screen controls & transcript
          if (foldableInfo.isTabletop) {
            return Column(
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVideoPlayerWithFloatingHud(),
                        const SizedBox(height: 8),
                        _buildPlayQuickBar(),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: _buildLiveControlBar(),
                      ),
                      Expanded(child: _buildTranscriptPanel()),
                    ],
                  ),
                ),
              ],
            );
          }

          // Dual-Screen (Book mode) or Foldable unfolded or Wide screen
          final isTwoPane =
              (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
              foldableInfo.isFoldableOrWide ||
              constraints.maxWidth >= 800;

          if (isTwoPane) {
            return Row(
              children: [
                Expanded(flex: 6, child: _buildVideoAndPlayerSection()),
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
                Expanded(flex: 4, child: _buildTranscriptPanel()),
              ],
            );
          }
          // Mobile/Compact view with tab switcher to prevent vertical overflows
          return Column(
            children: [
              _buildMobileTabBar(),
              Expanded(
                child: _activeViewTab == 0
                    ? _buildVideoAndPlayerSection()
                    : _buildTranscriptPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: [
          const ButtonSegment(
            value: 0,
            icon: Icon(Icons.smart_display_rounded, size: 16),
            label: Text('영상 & 컨트롤'),
          ),
          ButtonSegment(
            value: 1,
            icon: const Icon(Icons.subtitles_rounded, size: 16),
            label: Text('자막 타임라인 (${_subtitleHistory.length})'),
          ),
        ],
        selected: {_activeViewTab},
        onSelectionChanged: (set) {
          setState(() => _activeViewTab = set.first);
        },
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  Widget _buildVideoAndPlayerSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUrlBar(),
          const SizedBox(height: 12),
          _buildPresetsRow(),
          const SizedBox(height: 16),
          _buildVideoPlayerWithFloatingHud(),
          const SizedBox(height: 12),
          _buildPlayQuickBar(),
          const SizedBox(height: 16),
          _buildLiveControlBar(),
        ],
      ),
    );
  }

  Widget _buildPlayQuickBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _playVideo,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    '유튜브 재생 (오디오 캡처)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 클릭 시 브라우저에서 유튜브가 열리며, BlackHole 2ch를 통해 영상 소리가 실시간 번역 자막으로 변환됩니다.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _playVideo,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  '유튜브 재생 (오디오 캡처)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 클릭 시 브라우저에서 유튜브가 열리며, BlackHole 2ch를 통해 영상 소리가 실시간 번역 자막으로 변환됩니다.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUrlBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.ondemand_video, color: Colors.redAccent),
                hintText: 'YouTube 링크 또는 Video ID 입력 (e.g. XEzRZ33sJCE)',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _loadVideoFromInput(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.cyanAccent.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _loadVideoFromInput,
          child: const Text(
            '로드',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 비디오 프리셋:',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: kYouTubePresets.map((preset) {
            final isSelected = _currentVideoId == preset.videoId;
            return ChoiceChip(
              label: Text(preset.title),
              selected: isSelected,
              selectedColor: Colors.cyanAccent.shade700,
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _selectPreset(preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerWithFloatingHud() {
    final thumbnailUrl =
        'https://img.youtube.com/vi/$_currentVideoId/maxresdefault.jpg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Thumbnail (Clickable)
            GestureDetector(
              onTap: _playVideo,
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1E293B),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.smart_display,
                          color: Colors.redAccent,
                          size: 54,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video ID: $_currentVideoId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Subtle dark gradient for subtitle legibility
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent, Colors.black87],
                ),
              ),
            ),

            // Top Status Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.red.shade600
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isConnected)
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.circle, size: 8, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected ? 'LIVE SUBTITLES ON' : 'STANDBY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Target language pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Live Translate (gemini-3.5) ➔ ${_getTargetLanguageName()}',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Interactive YouTube Play Button
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _playVideo,
                  borderRadius: BorderRadius.circular(50),
                  hoverColor: Colors.white10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isConnected
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFFFF0000),
                                const Color(0xFFCC0000),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: _isConnected
                            ? Colors.cyanAccent.withValues(alpha: 0.5)
                            : Colors.white30,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.cyanAccent : Colors.red)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.open_in_browser_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isConnected ? '브라우저에서 영상 열기' : '영상 재생 & 실시간 자막 시작',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Cinematic Floating Subtitle HUD
            if (_showFloatingHud)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildFloatingSubtitleHud(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSubtitleHud() {
    final activeTranslated = _currentTranslatedSubtitle.trim();
    final activeOriginal = _currentOriginalSubtitle.trim();

    final lastEntry = _subtitleHistory.isNotEmpty
        ? _subtitleHistory.last
        : null;

    final displayOriginal = activeOriginal.isNotEmpty
        ? activeOriginal
        : (lastEntry != null ? lastEntry.originalText : '');
    final displayTranslated = activeTranslated.isNotEmpty
        ? activeTranslated
        : (lastEntry != null ? lastEntry.translatedText : '');

    final hasTranslated = displayTranslated.isNotEmpty;
    final hasOriginal = displayOriginal.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected
              ? Colors.cyanAccent.withValues(alpha: 0.5)
              : Colors.white12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Original Speech (Transcribed in real time)
          if (_showOriginalText && hasOriginal) ...[
            Text(
              displayOriginal,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: _subtitleFontSize * 0.75,
                fontStyle: FontStyle.italic,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Translated Subtitle (Prominent Real-time Streaming)
          Text(
            hasTranslated
                ? displayTranslated
                : (_isConnected
                      ? '실시간 음성을 스트리밍 통역 중입니다...'
                      : '스트리밍을 시작하면 실시간 통역 자막이 여기에 표시됩니다.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hasTranslated ? const Color(0xFFFDE047) : Colors.white38,
              fontSize: _subtitleFontSize,
              fontWeight: FontWeight.bold,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isNarrow) ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isAudioStreaming
                            ? Colors.cyanAccent.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAudioStreaming ? Icons.mic : Icons.mic_off,
                        color: _isAudioStreaming
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? (_isAudioStreaming
                                      ? '초저지연 번역 스트리밍 중'
                                      : '연결됨 (오디오 대기 중)')
                                : 'Live Translate (gemini-3.5) 자막기 오프라인',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _audioVolume,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _audioVolume > 0.6
                                    ? Colors.redAccent
                                    : (_audioVolume > 0.3
                                          ? Colors.yellowAccent
                                          : Colors.cyanAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isConnected
                          ? Colors.red.shade600
                          : Colors.cyanAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isConnecting ? null : _toggleConnection,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isConnected
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    label: Text(
                      _isConnected ? '자막 정지' : '실시간 자막 시작',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isAudioStreaming
                            ? Colors.cyanAccent.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAudioStreaming ? Icons.mic : Icons.mic_off,
                        color: _isAudioStreaming
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? (_isAudioStreaming
                                      ? '오디오 수음 및 초저지연 번역 스트리밍 중'
                                      : '연결됨 (오디오 대기 중)')
                                : 'Live Translate (gemini-3.5) 자막기 오프라인',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _audioVolume,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _audioVolume > 0.6
                                    ? Colors.redAccent
                                    : (_audioVolume > 0.3
                                          ? Colors.yellowAccent
                                          : Colors.cyanAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _isConnected
                            ? Colors.red.shade600
                            : Colors.cyanAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isConnecting ? null : _toggleConnection,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isConnected
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                      label: Text(
                        _isConnected ? '자막 정지' : '실시간 자막 시작',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.settings_voice_rounded,
                        size: 16,
                        color: Colors.cyanAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '오디오 입력 장치:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  _buildAudioDeviceSelectorButton(isCompact: false),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'HUD 옵션:',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('원문 함께 보기'),
                        selected: _showOriginalText,
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: Colors.cyanAccent.shade700,
                        labelStyle: TextStyle(
                          color: _showOriginalText
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 11,
                        ),
                        onSelected: (val) =>
                            setState(() => _showOriginalText = val),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('플로팅 자막'),
                        selected: _showFloatingHud,
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: Colors.cyanAccent.shade700,
                        labelStyle: TextStyle(
                          color: _showFloatingHud
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 11,
                        ),
                        onSelected: (val) =>
                            setState(() => _showFloatingHud = val),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.text_decrease,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: '글자 크기 축소',
                        onPressed: _subtitleFontSize > 14
                            ? () => setState(() => _subtitleFontSize -= 2)
                            : null,
                      ),
                      Text(
                        '${_subtitleFontSize.toInt()}pt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.text_increase,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: '글자 크기 확대',
                        onPressed: _subtitleFontSize < 28
                            ? () => setState(() => _subtitleFontSize += 2)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAudioDeviceSelectorButton({bool isCompact = false}) {
    final hasDevice = _selectedAudioDevice != null;
    final isBlackHole =
        _selectedAudioDevice?.label.toLowerCase().contains('blackhole') ??
        false;
    final label = hasDevice
        ? (_selectedAudioDevice!.label.isNotEmpty
              ? _selectedAudioDevice!.label
              : '입력 장치 (${_selectedAudioDevice!.id})')
        : '기본 마이크 (System Default)';

    return PopupMenuButton<String>(
      tooltip: '오디오 입력 장치 선택 (BlackHole / 마이크)',
      onOpened: _loadAudioDevices,
      onSelected: (deviceId) {
        if (deviceId == '__default__') {
          _switchAudioDevice(null);
        } else {
          final dev = _availableAudioDevices
              .where((d) => d.id == deviceId)
              .firstOrNull;
          _switchAudioDevice(dev);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: '__default__',
            child: Row(
              children: [
                Icon(
                  _selectedAudioDevice == null
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _selectedAudioDevice == null
                      ? Colors.cyanAccent
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('기본 마이크 (System Default)'),
              ],
            ),
          ),
          ..._availableAudioDevices.map((dev) {
            final isSelected = _selectedAudioDevice?.id == dev.id;
            final isBh = dev.label.toLowerCase().contains('blackhole');
            return PopupMenuItem<String>(
              value: dev.id,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected ? Colors.cyanAccent : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBh ? '🔈 ${dev.label} (시스템 오디오)' : dev.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isBh ? Colors.amberAccent : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isBlackHole
              ? Colors.amber.withValues(alpha: 0.15)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBlackHole
                ? Colors.amberAccent.withValues(alpha: 0.6)
                : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBlackHole
                  ? Icons.surround_sound_rounded
                  : (hasDevice ? Icons.mic_external_on : Icons.mic),
              size: isCompact ? 14 : 16,
              color: isBlackHole ? Colors.amberAccent : Colors.cyanAccent,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 130 : 220),
              child: Text(
                isBlackHole ? '🔈 $label' : label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isBlackHole ? Colors.amberAccent : Colors.white,
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptPanel() {
    final activeTranslated = _currentTranslatedSubtitle.trim();
    final activeOriginal = _currentOriginalSubtitle.trim();
    final hasActive = activeTranslated.isNotEmpty || activeOriginal.isNotEmpty;

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '실시간 자막 타임라인',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_subtitleHistory.length}개 문장',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _subtitleHistory.isEmpty && !hasActive
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.subtitles_off_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '수신된 자막 기록이 없습니다.\n실시간 자막을 시작하면 타임라인이 누적됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _logScrollController,
                    itemCount: _subtitleHistory.length + (hasActive ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index < _subtitleHistory.length) {
                        final item = _subtitleHistory[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.formatTime(),
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.originalText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.originalText,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                item.translatedText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Active streaming card (LIVE)
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 8,
                                        height: 8,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE 통역 중',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (activeOriginal.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                activeOriginal,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (activeTranslated.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                activeTranslated,
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
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
