import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'live_audio_player.dart';
import 'soloud_live_audio_player.dart';

/// Supported target languages for Gemini Live Translation.
const List<Map<String, String>> kTranslationLanguages = [
  {'code': 'ko', 'name': '한국어 (Korean)', 'flag': '🇰🇷'},
  {'code': 'en', 'name': 'English (영어)', 'flag': '🇺🇸'},
  {'code': 'ja', 'name': '日本語 (Japanese)', 'flag': '🇯🇵'},
  {'code': 'zh-Hans', 'name': '简体中文 (Chinese)', 'flag': '🇨🇳'},
  {'code': 'es', 'name': 'Español (Spanish)', 'flag': '🇪🇸'},
  {'code': 'fr', 'name': 'Français (French)', 'flag': '🇫🇷'},
  {'code': 'de', 'name': 'Deutsch (German)', 'flag': '🇩🇪'},
  {'code': 'vi', 'name': 'Tiếng Việt (Vietnamese)', 'flag': '🇻🇳'},
  {'code': 'th', 'name': 'ไทย (Thai)', 'flag': '🇹🇭'},
  {'code': 'id', 'name': 'Bahasa Indonesia (Indonesian)', 'flag': '🇮🇩'},
  {'code': 'ru', 'name': 'Русский (Russian)', 'flag': '🇷🇺'},
  {'code': 'it', 'name': 'Italiano (Italian)', 'flag': '🇮🇹'},
  {'code': 'pt-BR', 'name': 'Português (Portuguese)', 'flag': '🇧🇷'},
  {'code': 'ar', 'name': 'العربية (Arabic)', 'flag': '🇸🇦'},
  {'code': 'hi', 'name': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
];

class LiveTranslationMessage {
  final bool isUser;
  final String text;
  final String? languageCode;
  final DateTime timestamp;

  LiveTranslationMessage({
    required this.isUser,
    required this.text,
    this.languageCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class LiveTranslationPage extends StatefulWidget {
  const LiveTranslationPage({super.key});

  @override
  State<LiveTranslationPage> createState() => _LiveTranslationPageState();
}

class _LiveTranslationPageState extends State<LiveTranslationPage> {
  static const String _modelName = 'gemini-3.5-live-translate-preview';
  static const int _audioSampleRate = 16000;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  bool _useFallbackAudio = false;
  bool _isAudioOutputEnabled = true; // 음성 출력 (스피커) ON/OFF

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  LiveSession? _session;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMicActive = false;
  String _myLanguageCode = 'ko'; // 내 언어 (기본 한국어)
  String _targetLanguageCode = 'en'; // 상대방 언어 (기본 영어)
  final bool _echoTargetLanguage = true;
  bool _isDualFlipMode = true; // 양방향 분할 플립 모드 기본 활성화

  double _micVolume = 0.0;
  final List<LiveTranslationMessage> _history = [];
  final ScrollController _scrollController = ScrollController();
  final ScrollController _partnerScrollController = ScrollController();

  InputDevice? _selectedAudioDevice;

  @override
  void initState() {
    super.initState();
    _loadAudioDevice();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (!kIsWeb) {
      await _audioPlayer.init();
    } else {
      _useFallbackAudio = true;
    }
  }

  Future<void> _loadAudioDevice() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      final savedId = ApiKeyStore.audioDeviceId;
      if (savedId.isNotEmpty) {
        _selectedAudioDevice = devices.where((d) => d.id == savedId).firstOrNull;
      }
    } catch (_) {}
  }

  Timer? _webAudioFlushTimer;

  void _toggleAudioOutput() {
    setState(() {
      _isAudioOutputEnabled = !_isAudioOutputEnabled;
      if (!_isAudioOutputEnabled) {
        if (!_useFallbackAudio) {
          _audioPlayer.clear();
        } else {
          _fallbackAudioPlayer.clear();
        }
      }
    });
  }

  @override
  void dispose() {
    _webAudioFlushTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    unawaited(_audioPlayer.dispose());
    _fallbackAudioPlayer.dispose();
    _session?.close();
    _scrollController.dispose();
    _partnerScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      if (_partnerScrollController.hasClients) {
        _partnerScrollController.animateTo(
          _partnerScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
      final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
      final session = await genAI.live.connect(
        LiveConnectParameters(
          model: _modelName,
          config: GenerationConfig(
            responseModalities: const [Modality.AUDIO],
            translationConfig: TranslationConfig(
              targetLanguageCode: _targetLanguageCode,
              echoTargetLanguage: _echoTargetLanguage,
            ),
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(
                  voiceName: ApiKeyStore.voice,
                ),
              ),
            ),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              if (!mounted) return;
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
              _startMicStreaming();
            },
            onMessage: (message) {
              if (!mounted) return;
              _handleServerMessage(message);
            },
            onError: (error, stack) {
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                _isMicActive = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('세션 오류: $error')),
              );
            },
            onClose: (code, reason) {
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                _isMicActive = false;
              });
            },
          ),
        ),
      );

      setState(() => _session = session);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패: $e')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _stopMicStreaming();
    if (!_useFallbackAudio) {
      await _audioPlayer.stop();
    } else {
      await _fallbackAudioPlayer.stop();
    }
    await _session?.close();
    setState(() {
      _session = null;
      _isConnected = false;
      _isConnecting = false;
      _isMicActive = false;
    });
  }

  Future<void> _startMicStreaming() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
      }
      return;
    }

    try {
      final bool enableVoiceProc = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
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

      setState(() => _isMicActive = true);

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isMicActive || _session == null || !_isConnected) return;

        // Amplitude calculation for waveform indicator
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
              _micVolume = (_micVolume * 0.3) + (norm * 0.7);
            });
          }
        }

        final blob = Blob(
          mimeType: 'audio/pcm;rate=$_audioSampleRate',
          data: base64Encode(chunk),
        );
        _session!.sendRealtimeInput(audio: blob);
      });
    } catch (e) {
      debugPrint('Mic streaming start error: $e');
    }
  }

  Future<void> _stopMicStreaming() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isMicActive = false;
        _micVolume = 0.0;
      });
    }
  }

  void _feedAudioChunk(String base64Data) {
    if (!_isAudioOutputEnabled) return;
    if (!_useFallbackAudio) {
      _audioPlayer.appendBase64Chunk(base64Data);
    } else {
      _fallbackAudioPlayer.appendBase64Chunk(base64Data);
      _webAudioFlushTimer?.cancel();
      _webAudioFlushTimer = Timer(const Duration(milliseconds: 350), () {
        if (_isAudioOutputEnabled &&
            _fallbackAudioPlayer.hasBufferedAudio &&
            !_fallbackAudioPlayer.isPlaying) {
          unawaited(_fallbackAudioPlayer.playBufferedAudio());
        }
      });
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    // 1. Translated Audio output
    if (_isAudioOutputEnabled) {
      if (message.data != null && message.data!.isNotEmpty) {
        _feedAudioChunk(message.data!);
      }

      final parts = message.serverContent?.modelTurn?.parts;
      if (parts != null) {
        for (final part in parts) {
          final data = part.inlineData?.data;
          if (data != null && data.isNotEmpty) {
            _feedAudioChunk(data);
          }
        }
      }

      final turnComplete = message.serverContent?.turnComplete ?? false;
      if (turnComplete) {
        if (!_useFallbackAudio) {
          _audioPlayer.onTurnComplete();
        } else {
          _webAudioFlushTimer?.cancel();
          unawaited(_fallbackAudioPlayer.playBufferedAudio());
        }
      }
    }

    // 2. Transcriptions
    final inputTranscript = message.serverContent?.inputTranscription?.text;
    if (inputTranscript != null && inputTranscript.trim().isNotEmpty) {
      setState(() {
        _history.add(
          LiveTranslationMessage(
            isUser: true,
            text: inputTranscript.trim(),
            languageCode: message.serverContent?.inputTranscription?.languageCode,
          ),
        );
      });
      _scrollToBottom();
    }

    final outputTranscript = message.serverContent?.outputTranscription?.text;
    if (outputTranscript != null && outputTranscript.trim().isNotEmpty) {
      setState(() {
        _history.add(
          LiveTranslationMessage(
            isUser: false,
            text: outputTranscript.trim(),
            languageCode: message.serverContent?.outputTranscription?.languageCode ?? _targetLanguageCode,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myLang = kTranslationLanguages.firstWhere(
      (l) => l['code'] == _myLanguageCode,
      orElse: () => {'code': _myLanguageCode, 'name': _myLanguageCode, 'flag': '🌐'},
    );
    final targetLang = kTranslationLanguages.firstWhere(
      (l) => l['code'] == _targetLanguageCode,
      orElse: () => {'code': _targetLanguageCode, 'name': _targetLanguageCode, 'flag': '🌐'},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.translate_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Live Translation (동시통역)'),
          ],
        ),
        actions: [
          // Voice Output Toggle Button (번역 음성 스피커 출력 ON/OFF)
          IconButton(
            icon: Icon(
              _isAudioOutputEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isAudioOutputEnabled ? Colors.greenAccent : Colors.white54,
            ),
            tooltip: _isAudioOutputEnabled
                ? '번역 음성 출력 켜짐 (클릭하여 음소거)'
                : '번역 음성 출력 꺼짐 (클릭하여 켜기)',
            onPressed: _toggleAudioOutput,
          ),
          // Dual Flip Mode Toggle Button
          IconButton(
            icon: Icon(
              _isDualFlipMode ? Icons.splitscreen_rounded : Icons.chat_bubble_outline_rounded,
              color: _isDualFlipMode ? Colors.amber : null,
            ),
            tooltip: _isDualFlipMode ? '단일 채팅 모드로 전환' : '양방향 대면 모드(Dual Flip)로 전환',
            onPressed: () {
              setState(() => _isDualFlipMode = !_isDualFlipMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: '설정',
            onPressed: () async {
              final updated = await AppSettingsDialog.show(context);
              if (updated == true && mounted) {
                await _loadAudioDevice();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Language & Configuration Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 내 언어 선택기
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '내 언어:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: _myLanguageCode,
                        isDense: true,
                        underline: const SizedBox(),
                        items: kTranslationLanguages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(lang['flag'] ?? '', style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 4),
                                Text(
                                  lang['name']!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isConnected
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _myLanguageCode = val);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  // 언어 맞바꾸기(Swap) 버튼
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: Colors.blueAccent),
                    tooltip: '내 언어와 상대방 언어 맞바꾸기',
                    visualDensity: VisualDensity.compact,
                    onPressed: _isConnected
                        ? null
                        : () {
                            setState(() {
                              final temp = _myLanguageCode;
                              _myLanguageCode = _targetLanguageCode;
                              _targetLanguageCode = temp;
                            });
                          },
                  ),
                  const SizedBox(width: 6),
                  // 상대방 언어 선택기
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '상대방 언어:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                      ),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: _targetLanguageCode,
                        isDense: true,
                        underline: const SizedBox(),
                        items: kTranslationLanguages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(lang['flag'] ?? '', style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 4),
                                Text(
                                  lang['name']!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDualFlipMode ? Colors.amber.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDualFlipMode ? Icons.screen_rotation_rounded : Icons.chat_rounded,
                          size: 14,
                          color: _isDualFlipMode ? Colors.amber.shade900 : Colors.blueAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isDualFlipMode ? '테이블 대면 모드' : '일반 채팅 모드',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isDualFlipMode ? Colors.amber.shade900 : Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Voice output toggle pill (클릭하여 켜기/끄기)
                  InkWell(
                    onTap: _toggleAudioOutput,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isAudioOutputEnabled
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isAudioOutputEnabled
                              ? Colors.greenAccent.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isAudioOutputEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 14,
                            color: _isAudioOutputEnabled
                                ? Colors.greenAccent
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isAudioOutputEnabled ? '음성 출력 ON' : '음성 출력 OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isAudioOutputEnabled
                                  ? Colors.greenAccent
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content Area (Dual Flip Mode vs Standard Chat Mode)
          Expanded(
            child: _isDualFlipMode
                ? _buildDualFlipLayout(myLang, targetLang)
                : _buildStandardChatLayout(myLang, targetLang),
          ),

          // 3. Waveform & Controls Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Mic amplitude meter
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMicActive
                          ? Colors.redAccent.withValues(alpha: 0.15 + (_micVolume * 0.8))
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      _isMicActive ? Icons.mic : Icons.mic_off,
                      color: _isMicActive ? Colors.redAccent : Colors.grey,
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
                              ? (_isMicActive ? '실시간 동시통역 중 (말씀하시면 즉시 번역됩니다)' : '마이크 일시 정지됨')
                              : (_isConnecting ? 'Live Translate 서버 연결 중...' : '준비 완료 (통역 시작을 누르세요)'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isConnected ? Colors.green.shade700 : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _isMicActive ? (_micVolume * 2.5).clamp(0.0, 1.0) : 0.0,
                            minHeight: 4,
                            backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _micVolume > 0.05 ? Colors.greenAccent.shade700 : Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isConnected) ...[
                    IconButton.filledTonal(
                      onPressed: () {
                        if (_isMicActive) {
                          _stopMicStreaming();
                        } else {
                          _startMicStreaming();
                        }
                      },
                      icon: Icon(_isMicActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      tooltip: _isMicActive ? '마이크 일시중지' : '마이크 재개',
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: _disconnect,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('종료'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.translate_rounded),
                      label: Text(_isConnecting ? '연결 중...' : '통역 시작'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 양방향 대면 분할 뷰 (테이블 맞은편 상대방을 위한 180도 회전 뷰)
  Widget _buildDualFlipLayout(Map<String, String> myLang, Map<String, String> targetLang) {
    // 상대방(외국인)에게 보여줄 번역문 메시지 목록 (모델 출력 위주)
    final partnerMessages = _history.where((m) => !m.isUser).toList();
    // 내게 보여줄 원문 및 번역문 전체 목록
    final myMessages = _history;

    return Column(
      children: [
        // 상단 절반: 맞은편 상대방 화면 (180도 회전!)
        Expanded(
          child: Container(
            color: Colors.amber.shade50.withValues(alpha: 0.35),
            child: Transform.rotate(
              angle: math.pi, // 180도 회전! 상대방이 똑바로 볼 수 있음
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(targetLang['flag'] ?? '🌐', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'For Partner: ${targetLang['name']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.person_pin_rounded, size: 18, color: Colors.amber),
                      ],
                    ),
                    const Divider(height: 12),
                    Expanded(
                      child: partnerMessages.isEmpty
                          ? Center(
                              child: Text(
                                _isConnected
                                  ? 'Listening...\nTranslations (${targetLang['name']}) will appear here for your partner.'
                                  : 'Waiting for session to start.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _partnerScrollController,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: partnerMessages.length,
                              itemBuilder: (context, idx) {
                                final msg = partnerMessages[idx];
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 중앙 분할선 (테이블 중앙 구분바)
        Container(
          height: 28,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                '맞은편 상대방: ${targetLang['name']} (180° 회전 화면)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 14, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                '내 화면: ${myLang['name']} (정방향)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.blueAccent),
            ],
          ),
        ),

        // 하단 절반: 내 화면 (정방향 및 통역 기록)
        Expanded(
          child: Container(
            color: Colors.blue.shade50.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(myLang['flag'] ?? '🇰🇷', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '내 화면 (${myLang['name']} 발화 및 통역 기록)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.person_rounded, size: 18, color: Colors.blueAccent),
                  ],
                ),
                const Divider(height: 12),
                Expanded(
                  child: myMessages.isEmpty
                      ? Center(
                          child: Text(
                            _isConnected
                                ? '마이크로 ${myLang['name']}로 말씀하세요.\n내 음성과 상대방 번역 내용(${targetLang['name']})이 실시간으로 기록됩니다.'
                                : '하단 통역 시작 버튼을 누르면 실시간 통역이 시작됩니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: myMessages.length,
                          itemBuilder: (context, idx) {
                            final msg = myMessages[idx];
                            return Align(
                              alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: msg.isUser
                                      ? Colors.blueAccent.shade700
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: msg.isUser ? null : Border.all(color: Colors.blue.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.isUser ? '🎤 내 발화 (${myLang['name']})' : '🌐 번역문 (${targetLang['name']})',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: msg.isUser ? Colors.white70 : Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: msg.isUser ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 💬 일반 채팅형 단일 레이아웃
  Widget _buildStandardChatLayout(Map<String, String> myLang, Map<String, String> targetLang) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected
                  ? '마이크로 ${myLang['name']}로 말하기를 시작하세요.\n원문과 번역문(${targetLang['name']})이 실시간 음성/자막으로 출력됩니다.'
                  : '하단의 "통역 시작" 버튼을 눌러 실시간 번역 세션을 연결하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Align(
          alignment: item.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: item.isUser
                  ? Colors.blueAccent.shade700
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(item.isUser ? 14 : 2),
                bottomRight: Radius.circular(item.isUser ? 2 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  item.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isUser ? Icons.mic : Icons.translate,
                      size: 13,
                      color: item.isUser ? Colors.white70 : Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isUser ? '내 음성 (${myLang['name']})' : '통역 결과 (${targetLang['name']})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isUser ? Colors.white70 : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isUser ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
