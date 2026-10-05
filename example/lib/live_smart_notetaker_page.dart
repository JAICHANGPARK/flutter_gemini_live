import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'foldable_utils.dart';
import 'live_api_defaults.dart';
import 'scrollable_app_bar_actions.dart';

/// Target languages for meeting / lecture translation.
const List<Map<String, String>> kNoteLanguages = [
  {'code': 'ko', 'name': '한국어 (Korean)', 'flag': '🇰🇷'},
  {'code': 'en', 'name': 'English (영어)', 'flag': '🇺🇸'},
  {'code': 'ja', 'name': '日本語 (Japanese)', 'flag': '🇯🇵'},
  {'code': 'zh-Hans', 'name': '简体中文 (Chinese)', 'flag': '🇨🇳'},
  {'code': 'es', 'name': 'Español (Spanish)', 'flag': '🇪🇸'},
  {'code': 'fr', 'name': 'Français (French)', 'flag': '🇫🇷'},
  {'code': 'de', 'name': 'Deutsch (German)', 'flag': '🇩🇪'},
];

/// An individual speech turn in the live audio timeline.
class LiveSpeechTurn {
  final String speakerText;
  final String? translatedText;
  final DateTime timestamp;

  LiveSpeechTurn({
    required this.speakerText,
    this.translatedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String formatTime() {
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// An extracted action item with checkbox state.
class NoteActionItem {
  final String title;
  bool isCompleted;

  NoteActionItem({required this.title, this.isCompleted = false});
}

class LiveSmartNotePage extends StatefulWidget {
  const LiveSmartNotePage({super.key});

  @override
  State<LiveSmartNotePage> createState() => _LiveSmartNotePageState();
}

class _LiveSmartNotePageState extends State<LiveSmartNotePage>
    with SingleTickerProviderStateMixin {
  static const int _audioSampleRate = 16000;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ScrollController _timelineScrollController = ScrollController();
  final ScrollController _noteScrollController = ScrollController();

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  LiveSession? _session;

  // Session state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isRecording = false;

  // Session timer
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  // Target translation language
  String _targetLanguageCode = 'ko';

  // Live Speech Feed
  String _interimSpeech = '';
  final List<LiveSpeechTurn> _speechTurns = [];

  // Smart Notes
  final StringBuffer _rawNotesBuffer = StringBuffer();
  final List<String> _keyTakeaways = [];
  final List<NoteActionItem> _actionItems = [];
  final List<String> _glossaryTerms = [];

  // Audio level
  double _audioVolume = 0.0;
  InputDevice? _selectedAudioDevice;
  List<InputDevice> _availableAudioDevices = [];

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: 'gemini-3.1-flash-live-preview',
  );

  // Active Tab for Mobile / Split View
  int _activeViewTab = 0; // 0: Timeline, 1: Smart Notes, 2: Action Items

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadAudioDevices();
    _appendInitialNoteGuide();
  }

  void _appendInitialNoteGuide() {
    _rawNotesBuffer.writeln('# 🎙️ 실시간 AI 회의 및 강의 노트');
    _rawNotesBuffer.writeln(
      '> **Gemini 3.8 Live**가 실시간 오디오를 청취하여 '
      '실시간 통번역 및 핵심 메모를 자동으로 구조화합니다.\n',
    );
    _rawNotesBuffer.writeln('### 💡 안내');
    _rawNotesBuffer.writeln(
      '- **녹음 시작** 버튼을 누르면 발표자의 발화가 실시간으로 분석됩니다.\n'
      '- 외국어 발화는 선택한 언어로 즉시 번역되며, 주요 논점과 액션 아이템이 자동 추출됩니다.\n',
    );
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

    if (_isRecording) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      _isRecording = false;
      if (mounted) {
        await _startAudioRecording();
      }
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pulseController.dispose();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _session?.close();
    _timelineScrollController.dispose();
    _noteScrollController.dispose();
    _usageTracker.dispose();
    super.dispose();
  }

  String _formatElapsedTime() {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _getTargetLanguageName() {
    final lang = kNoteLanguages.firstWhere(
      (e) => e['code'] == _targetLanguageCode,
      orElse: () => {'name': '한국어 (Korean)'},
    );
    return lang['name'] ?? 'Korean';
  }

  Future<void> _toggleSession() async {
    if (_isConnected) {
      await _stopSession();
    } else {
      await _startSession();
    }
  }

  Future<void> _startSession() async {
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
      final targetLang = _getTargetLanguageName();
      final systemPrompt =
          '''
You are an expert real-time AI lecture and meeting note-taker.
Your mission:
1. Listen to the continuous live audio stream.
2. In real-time, translate any foreign speech into $targetLang.
3. Automatically structure clear, well-organized lecture/meeting notes in Markdown.
4. When important insights appear, mark them with "[KEY] insight".
5. When tasks, action items, or decisions occur, mark them with "[ACTION] task description".
6. When important terms or concepts are defined, mark them with "[TERM] concept: definition".
7. Deliver concise, high-value professional notes without small talk or filler text.
''';

      final genAI = GoogleGenAI(
        apiKey: ApiKeyStore.apiKey,
        logger: (msg) => debugPrint('[GeminiLive Note] $msg'),
      );
      final modelToUse = ApiKeyStore.liveModel.isNotEmpty
          ? ApiKeyStore.liveModel
          : kCompatibilityLiveModel;

      final session = await genAI.live.connect(
        LiveConnectParameters(
          model: modelToUse,
          config: GenerationConfig(
            responseModalities: const [Modality.AUDIO],
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(
                  voiceName: ApiKeyStore.voice,
                ),
              ),
            ),
            temperature: 0.3,
          ),
          realtimeInputConfig: RealtimeInputConfig(
            automaticActivityDetection: AutomaticActivityDetection(
              disabled: false,
              startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
              endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_HIGH,
              prefixPaddingMs: 100,
              silenceDurationMs: 300,
            ),
          ),
          systemInstruction: Content(parts: [Part(text: systemPrompt)]),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              debugPrint('[GeminiLive Note] 🌐 onOpen received');
            },
            onMessage: (message) {
              if (!mounted) return;
              _handleLiveMessage(message);
            },
            onError: (err, _) {
              debugPrint('[GeminiLive Note] ❌ onError: $err');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Live 세션 오류: $err')));
            },
            onClose: (code, reason) {
              debugPrint(
                '[GeminiLive Note] 🔒 onClose (code: $code, reason: $reason)',
              );
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                _isRecording = false;
              });
              _sessionTimer?.cancel();
              if (reason != null && reason.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('세션 종료 ($code): $reason')),
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
          _elapsedSeconds = 0;
        });
        _startSessionTimer();
        await _startAudioRecording();
      }
    } catch (e) {
      debugPrint('[GeminiLive Note] 🚨 Connection failed: $e');
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('세션 시작 실패: $e')));
      }
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _handleLiveMessage(LiveServerMessage message) {
    // Record real-time token and cost metrics
    _usageTracker.recordMessage(message);

    // 1. Check interim/final speech transcription (Speaker)
    final speakerText =
        message.serverContent?.interimInputTranscription?.text ??
        message.serverContent?.inputTranscription?.text;

    if (speakerText != null && speakerText.trim().isNotEmpty) {
      setState(() {
        _interimSpeech = speakerText.trim();
      });
    }

    // 2. Check generated note content from Gemini Live
    final noteChunk = visibleModelText(message);
    if (noteChunk != null && noteChunk.trim().isNotEmpty) {
      _processNoteChunk(noteChunk);
    }

    // 3. Turn complete
    if (message.serverContent?.turnComplete == true ||
        message.serverContent?.interactionStatus == InteractionStatus.IDLE) {
      if (_interimSpeech.isNotEmpty) {
        setState(() {
          _speechTurns.add(
            LiveSpeechTurn(
              speakerText: _interimSpeech,
              translatedText: noteChunk,
            ),
          );
          _interimSpeech = '';
        });

        // Scroll timeline to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timelineScrollController.hasClients) {
            _timelineScrollController.animateTo(
              _timelineScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _processNoteChunk(String chunk) {
    setState(() {
      _rawNotesBuffer.write(chunk);
      _rawNotesBuffer.writeln();

      // Parse structured tags in real-time
      final lines = chunk.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('[KEY]') || trimmed.contains('[KEY]')) {
          final text = trimmed.replaceAll(RegExp(r'.*?\[KEY\]'), '').trim();
          if (text.isNotEmpty && !_keyTakeaways.contains(text)) {
            _keyTakeaways.add(text);
          }
        } else if (trimmed.startsWith('[ACTION]') ||
            trimmed.contains('[ACTION]')) {
          final text = trimmed.replaceAll(RegExp(r'.*?\[ACTION\]'), '').trim();
          if (text.isNotEmpty && !_actionItems.any((a) => a.title == text)) {
            _actionItems.add(NoteActionItem(title: text));
          }
        } else if (trimmed.startsWith('[TERM]') || trimmed.contains('[TERM]')) {
          final text = trimmed.replaceAll(RegExp(r'.*?\[TERM\]'), '').trim();
          if (text.isNotEmpty && !_glossaryTerms.contains(text)) {
            _glossaryTerms.add(text);
          }
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_noteScrollController.hasClients) {
        _noteScrollController.animateTo(
          _noteScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startAudioRecording() async {
    if (_isRecording) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다.')));
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

      setState(() => _isRecording = true);

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isRecording || _session == null || !_isConnected) return;

        // Calculate audio volume peak
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

        // Send PCM chunk
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
        ).showSnackBar(SnackBar(content: Text('오디오 녹음 시작 오류: $e')));
      }
    }
  }

  Future<void> _stopSession() async {
    _sessionTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _audioRecorder.stop();
    _session?.close();
    _session = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _isRecording = false;
        _audioVolume = 0.0;
      });
    }
  }

  void _generateWrapUpSummary() {
    if (_speechTurns.isEmpty && _rawNotesBuffer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('요약할 회의/강의 내용이 없습니다.')));
      return;
    }

    if (_session != null && _isConnected) {
      _session!.sendClientContent(
        turns: [
          Content(
            parts: [
              Part(
                text:
                    '지금까지 청취한 전체 내용을 바탕으로 [최종 결론 요약 (Executive Summary)]'
                    '과 [핵심 액션 아이템]을 명확한 마크다운 리포트로 최종 정리해줘.',
              ),
            ],
          ),
        ],
        turnComplete: true,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI에게 최종 요약 정리를 요청했습니다...')));
    }
  }

  void _copyNotesToClipboard() {
    final fullText = _rawNotesBuffer.toString();
    if (fullText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복사할 노트 내용이 없습니다.')));
      return;
    }
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스마트 마크다운 노트가 클립보드에 복사되었습니다!')),
    );
  }

  void _clearNotes() {
    setState(() {
      _speechTurns.clear();
      _rawNotesBuffer.clear();
      _keyTakeaways.clear();
      _actionItems.clear();
      _glossaryTerms.clear();
      _interimSpeech = '';
      _elapsedSeconds = 0;
      _usageTracker.reset();
      _appendInitialNoteGuide();
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
              : Colors.amberAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: foldableInfo.isTabletop
                ? Colors.deepOrangeAccent
                : Colors.amberAccent,
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
                  : Colors.amberAccent,
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
                    : Colors.amberAccent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.amberAccent, size: 26),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live Smart NoteTaker',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131B2E),
        foregroundColor: Colors.white,
        actions: [
          ScrollableAppBarActions(
            children: [
              foldablePill(),
              // Target Language Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _targetLanguageCode,
                    dropdownColor: const Color(0xFF131B2E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.amberAccent,
                    ),
                    items: kNoteLanguages.map((lang) {
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
                icon: const Icon(Icons.summarize_rounded),
                tooltip: 'AI 최종 요약본 정리',
                onPressed: _isConnected ? _generateWrapUpSummary : null,
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_rounded),
                tooltip: '마크다운 전체 복사',
                onPressed: _copyNotesToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: '새 노트 시작 (초기화)',
                onPressed: _clearNotes,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionStatusBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tabletop / Flex mode: Top half timeline, bottom half notes board
                if (foldableInfo.isTabletop) {
                  return Column(
                    children: [
                      Expanded(flex: 1, child: _buildLiveTimelinePanel()),
                      Container(
                        height: 3,
                        color: Colors.amberAccent.withValues(alpha: 0.6),
                      ),
                      Expanded(flex: 1, child: _buildSmartNotesBoard()),
                    ],
                  );
                }

                // Dual-Screen (Book mode) or Foldable unfolded or Wide screen
                final isTwoPane =
                    (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
                    foldableInfo.isFoldableOrWide ||
                    constraints.maxWidth >= 780;

                if (isTwoPane) {
                  return Row(
                    children: [
                      // Left: Live Speech Stream & Audio Waveform (40%)
                      Expanded(flex: 4, child: _buildLiveTimelinePanel()),
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
                      // Right: Smart Note Board & Markdown Canvas (60%)
                      Expanded(flex: 6, child: _buildSmartNotesBoard()),
                    ],
                  );
                }

                // Mobile view with tab switcher
                return Column(
                  children: [
                    _buildMobileTabBar(),
                    Expanded(
                      child: _activeViewTab == 0
                          ? _buildLiveTimelinePanel()
                          : _activeViewTab == 1
                          ? _buildSmartNotesBoard()
                          : _buildActionItemsPanel(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      color: const Color(0xFF131B2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            icon: const Icon(Icons.mic, size: 16),
            label: Text('실시간 발화 (${_speechTurns.length})'),
          ),
          const ButtonSegment(
            value: 1,
            icon: Icon(Icons.description, size: 16),
            label: Text('스마트 노트'),
          ),
          ButtonSegment(
            value: 2,
            icon: const Icon(Icons.checklist_rtl, size: 16),
            label: Text('할일 (${_actionItems.length})'),
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

  Widget _buildSessionStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF131B2E),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_isConnected)
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.radio_button_unchecked,
                        size: 10,
                        color: Colors.grey,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isConnected
                            ? 'RECORDING & TRANSLATING'
                            : 'READY TO RECORD',
                        style: TextStyle(
                          color: _isConnected
                              ? Colors.redAccent
                              : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatElapsedTime(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _audioVolume,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _audioVolume > 0.6
                                ? Colors.redAccent
                                : (_audioVolume > 0.3
                                      ? Colors.amberAccent
                                      : Colors.greenAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAudioDeviceSelectorButton(isCompact: true),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _isConnected
                            ? Colors.red.shade600
                            : Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isConnecting ? null : _toggleSession,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isConnected
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isConnected ? '종료' : '녹음 시작',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              // Recording Pulse Indicator
              if (_isConnected)
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.radio_button_unchecked,
                  size: 12,
                  color: Colors.grey,
                ),
              const SizedBox(width: 10),
              Text(
                _isConnected ? 'RECORDING & TRANSLATING' : 'READY TO RECORD',
                style: TextStyle(
                  color: _isConnected ? Colors.redAccent : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatElapsedTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Audio level indicator
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _audioVolume,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _audioVolume > 0.6
                          ? Colors.redAccent
                          : (_audioVolume > 0.3
                                ? Colors.amberAccent
                                : Colors.greenAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildAudioDeviceSelectorButton(isCompact: false),
              const SizedBox(width: 16),
              // Start / Stop Session Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _isConnected
                      ? Colors.red.shade600
                      : Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isConnecting ? null : _toggleSession,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isConnected ? Icons.stop_rounded : Icons.mic_rounded,
                      ),
                label: Text(
                  _isConnected ? '세션 종료' : '노트 녹음 시작',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                      ? Colors.amberAccent
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
                    color: isSelected ? Colors.amberAccent : Colors.grey,
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
              : const Color(0xFF1E293B),
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
              constraints: BoxConstraints(maxWidth: isCompact ? 130 : 200),
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

  Widget _buildLiveTimelinePanel() {
    return Container(
      color: const Color(0xFF090D16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '실시간 발화 & 동시 번역',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_speechTurns.length}개 발화',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _speechTurns.isEmpty && _interimSpeech.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '녹음을 시작하면 회의/강의 발화가\n실시간으로 텍스트화 및 번역됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _timelineScrollController,
                    itemCount:
                        _speechTurns.length +
                        (_interimSpeech.isNotEmpty ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index < _speechTurns.length) {
                        final turn = _speechTurns[index];
                        return _buildSpeechBubble(turn);
                      }
                      // Interim live speech bubble
                      return _buildInterimBubble();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(LiveSpeechTurn turn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  turn.formatTime(),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '발표자 발화',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            turn.speakerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterimBubble() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '실시간 청취 중...',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _interimSpeech,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartNotesBoard() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Quick Insights Tags
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI 실시간 구조화 노트',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.amberAccent,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _copyNotesToClipboard,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text(
                  'Markdown 복사',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key Highlights Chips Bar
          if (_keyTakeaways.isNotEmpty || _actionItems.isNotEmpty)
            _buildHighlightsSummaryBar(),

          const SizedBox(height: 12),

          // Main Markdown Note Canvas
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                controller: _noteScrollController,
                child: MarkdownBody(
                  data: _rawNotesBuffer.toString(),
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    p: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    blockquote: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: const Border(
                        left: BorderSide(color: Colors.amberAccent, width: 3),
                      ),
                    ),
                    code: const TextStyle(
                      color: Colors.lightGreenAccent,
                      backgroundColor: Colors.black26,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.amberAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '핵심 요약 ${_keyTakeaways.length}건 · 액션 아이템 ${_actionItems.length}건 감지됨',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_actionItems.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.cyanAccent,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF131B2E),
                  builder: (_) => _buildActionItemsPanel(),
                );
              },
              child: const Text('할 일 목록 보기 ➔', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionItemsPanel() {
    return Container(
      color: const Color(0xFF131B2E),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.checklist_rtl_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '액션 아이템 & 할 일 체크리스트',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${_actionItems.where((a) => a.isCompleted).length} / ${_actionItems.length} 완료',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _actionItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '감지된 액션 아이템이 없습니다.\n회의 중 과제나 할 일이 언급되면 자동 추가됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _actionItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _actionItems[index];
                      return CheckboxListTile(
                        value: item.isCompleted,
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isCompleted
                                ? Colors.white38
                                : Colors.white,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            fontSize: 13,
                          ),
                        ),
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.black,
                        tileColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.isCompleted = val ?? false;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
