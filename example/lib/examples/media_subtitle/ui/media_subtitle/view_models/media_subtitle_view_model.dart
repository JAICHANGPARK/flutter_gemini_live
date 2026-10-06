import 'dart:async';

import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../../data/repositories/audio_device_repository.dart';
import '../../../data/services/media_subtitle_browser_service.dart';
import '../../../data/services/media_subtitle_clipboard_service.dart';
import '../../../data/services/media_subtitle_live_service.dart';
import '../../../data/services/media_subtitle_mic_service.dart';
import '../../../domain/models/subtitle_entry.dart';
import '../../../domain/models/subtitle_languages.dart';
import '../../../domain/models/youtube_preset.dart';
import '../../../domain/subtitle_transcript.dart';
import '../../../domain/youtube_id_extractor.dart';
import 'media_subtitle_notice.dart';

/// State + logic for the Live Media Subtitles screen.
///
/// Coarse state (connection, video, HUD options, audio device, tab) notifies
/// through [ChangeNotifier]. High-frequency state lives on dedicated
/// [ValueNotifier]s: [audioVolume] (mic level) and [subtitleRevision] (bumped
/// whenever the subtitle history or the in-flight subtitle text changes).
///
/// The view model never touches a `BuildContext`; it asks the view for things
/// via [onNotice], [requestApiKeySetup], [onScrollToEnd], [getUrlText] and
/// [setUrlText].
class MediaSubtitleViewModel extends ChangeNotifier {
  MediaSubtitleViewModel({
    MediaSubtitleLiveService? liveService,
    MediaSubtitleMicService? micService,
    MediaSubtitleBrowserService? browserService,
    MediaSubtitleClipboardService? clipboardService,
    AudioDeviceRepository? audioDeviceRepository,
    GeminiTokenUsageTracker? usageTracker,
  }) : _live = liveService ?? MediaSubtitleLiveService(),
       _mic = micService ?? MediaSubtitleMicService(),
       _browser = browserService ?? MediaSubtitleBrowserService(),
       _clipboard = clipboardService ?? MediaSubtitleClipboardService(),
       _audioDevices = audioDeviceRepository ?? AudioDeviceRepository(),
       _usageTracker =
           usageTracker ??
           GeminiTokenUsageTracker(model: 'gemini-3.5-live-translate-preview');

  final MediaSubtitleLiveService _live;
  final MediaSubtitleMicService _mic;
  final MediaSubtitleBrowserService _browser;
  final MediaSubtitleClipboardService _clipboard;
  final AudioDeviceRepository _audioDevices;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(MediaSubtitleNotice notice)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  /// Scroll the timeline log to its end after the next frame.
  void Function(Duration duration)? onScrollToEnd;

  /// Reads the current text of the URL field.
  String Function()? getUrlText;

  /// Replaces the text of the URL field.
  void Function(String text)? setUrlText;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _notice(String message, MediaSubtitleNoticeKind kind) {
    if (_disposed) return;
    onNotice?.call(MediaSubtitleNotice(message, kind));
  }

  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Session state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isAudioStreaming = false;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isAudioStreaming => _isAudioStreaming;

  // Current Video ID
  String _currentVideoId = 'jV1vkHv4zq8'; // Default: Google Gemini AI
  String get currentVideoId => _currentVideoId;

  // Subtitle state
  String _targetLanguageCode = 'ko';
  String _currentOriginalSubtitle = '';
  String _currentTranslatedSubtitle = '';
  final List<SubtitleEntry> _subtitleHistory = [];

  String get targetLanguageCode => _targetLanguageCode;
  String get currentOriginalSubtitle => _currentOriginalSubtitle;
  String get currentTranslatedSubtitle => _currentTranslatedSubtitle;
  List<SubtitleEntry> get subtitleHistory => _subtitleHistory;

  /// Bumped whenever [subtitleHistory] or the in-flight subtitle changes.
  final ValueNotifier<int> subtitleRevision = ValueNotifier<int>(0);

  void _bumpSubtitles() {
    if (_disposed) return;
    subtitleRevision.value++;
  }

  // Audio level meter
  /// Smoothed mic peak level (0..1).
  final ValueNotifier<double> audioVolume = ValueNotifier<double>(0.0);
  InputDevice? _selectedAudioDevice;
  List<InputDevice> _availableAudioDevices = [];

  InputDevice? get selectedAudioDevice => _selectedAudioDevice;
  List<InputDevice> get availableAudioDevices => _availableAudioDevices;

  // Floating HUD settings (Default to false so subtitles focus in timeline)
  bool _showFloatingHud = false;
  bool _showOriginalText = true;
  double _subtitleFontSize = 18.0;

  bool get showFloatingHud => _showFloatingHud;
  bool get showOriginalText => _showOriginalText;
  double get subtitleFontSize => _subtitleFontSize;

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker _usageTracker;
  GeminiTokenUsageTracker get usageTracker => _usageTracker;

  // Responsive view tab (0: Video & Controls, 1: Subtitle Transcript)
  int _activeViewTab = 0;
  int get activeViewTab => _activeViewTab;

  set activeViewTab(int tab) {
    _activeViewTab = tab;
    notifyListeners();
  }

  void setTargetLanguage(String code) {
    _targetLanguageCode = code;
    notifyListeners();
  }

  void setShowOriginalText(bool value) {
    _showOriginalText = value;
    notifyListeners();
  }

  void setShowFloatingHud(bool value) {
    _showFloatingHud = value;
    notifyListeners();
  }

  void decreaseFontSize() {
    _subtitleFontSize -= 2;
    notifyListeners();
  }

  void increaseFontSize() {
    _subtitleFontSize += 2;
    notifyListeners();
  }

  /// The initial URL text for the URL field.
  String get initialUrlText =>
      'https://www.youtube.com/watch?v=$_currentVideoId';

  void init() {
    loadAudioDevices();
  }

  @override
  void dispose() {
    _disposed = true;
    _audioStreamSubscription?.cancel();
    unawaited(_mic.dispose());
    _live.close();
    _usageTracker.dispose();
    subtitleRevision.dispose();
    audioVolume.dispose();
    super.dispose();
  }

  Future<void> loadAudioDevices() async {
    try {
      final devices = await _mic.listInputDevices();
      if (!_disposed) {
        _availableAudioDevices = devices;
        final savedId = _audioDevices.savedDeviceId;
        if (savedId.isNotEmpty) {
          _selectedAudioDevice = devices
              .where((d) => d.id == savedId)
              .firstOrNull;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> switchAudioDevice(InputDevice? device) async {
    if (_selectedAudioDevice?.id == device?.id) return;
    _selectedAudioDevice = device;
    notifyListeners();
    await _audioDevices.save(device?.id ?? '', device?.label ?? '');

    if (_isAudioStreaming) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _mic.stop();
      } catch (_) {}
      _isAudioStreaming = false;
      if (!_disposed) {
        await _startAudioStreaming();
      }
    }
  }

  void loadVideoFromInput() {
    final id = extractYouTubeId(getUrlText?.call() ?? '');
    if (id.isNotEmpty && id.length == 11) {
      _currentVideoId = id;
      notifyListeners();
      _notice('YouTube 영상이 로드되었습니다: $id', MediaSubtitleNoticeKind.brief);
    } else {
      _notice(
        '올바른 YouTube URL 또는 11자리 비디오 ID를 입력하세요.',
        MediaSubtitleNoticeKind.error,
      );
    }
  }

  void selectPreset(YouTubePreset preset) {
    _currentVideoId = preset.videoId;
    setUrlText?.call('https://www.youtube.com/watch?v=${preset.videoId}');
    notifyListeners();
  }

  Future<void> playVideo() async {
    final url = 'https://www.youtube.com/watch?v=$_currentVideoId';
    await _browser.open(url);
    if (!_disposed) {
      _notice(
        'YouTube 영상을 브라우저에서 재생합니다: $url\nBlackHole을 통해 오디오가 실시간 자막으로 번역됩니다.',
        MediaSubtitleNoticeKind.playing,
      );
      if (!_isConnected && !_isConnecting) {
        await connect();
      }
    }
  }

  String get targetLanguageName {
    final lang = kSubtitleLanguages.firstWhere(
      (e) => e['code'] == _targetLanguageCode,
      orElse: () => {'name': '한국어 (Korean)'},
    );
    return lang['name'] ?? 'Korean';
  }

  Future<void> toggleConnection() async {
    if (_isConnected) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (!_audioDevices.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !_audioDevices.hasApiKey) {
        _notice('Gemini API 키가 설정되지 않았습니다.', MediaSubtitleNoticeKind.plain);
        return;
      }
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final session = await _live.connect(
        targetLanguageCode: _targetLanguageCode,
        onOpen: () {
          debugPrint('[GeminiLive Subtitle] 🌐 onOpen received');
        },
        onMessage: (message) {
          if (_disposed) return;
          _handleLiveMessage(message);
        },
        onError: (err, _) {
          debugPrint('[GeminiLive Subtitle] ❌ onError: $err');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
          _notice('Live API 오류: $err', MediaSubtitleNoticeKind.plain);
        },
        onClose: (code, reason) {
          debugPrint(
            '[GeminiLive Subtitle] 🔒 onClose (code: $code, reason: $reason)',
          );
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          _isAudioStreaming = false;
          notifyListeners();
          if (reason != null && reason.isNotEmpty) {
            _notice(
              'Live 연결 종료 ($code): $reason',
              MediaSubtitleNoticeKind.plain,
            );
          }
        },
      );

      if (!_disposed) {
        _live.attach(session);
        _isConnected = true;
        _isConnecting = false;
        notifyListeners();
        await _startAudioStreaming();
      }
    } catch (e) {
      debugPrint('[GeminiLive Subtitle] 🚨 Connection failed: $e');
      if (!_disposed) {
        _isConnecting = false;
        notifyListeners();
        _notice('연결 실패: $e', MediaSubtitleNoticeKind.plain);
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
      onScrollToEnd?.call(const Duration(milliseconds: 200));
    }

    if (stateChanged && !_disposed) {
      _bumpSubtitles();
      onScrollToEnd?.call(const Duration(milliseconds: 100));
    }
  }

  Future<void> _startAudioStreaming() async {
    if (_isAudioStreaming) return;

    final hasPermission = await _mic.hasPermission();
    if (!hasPermission) {
      _notice('마이크/오디오 캡처 권한이 필요합니다.', MediaSubtitleNoticeKind.plain);
      return;
    }

    try {
      final stream = await _mic.startStream(device: _selectedAudioDevice);

      // The original `setState` threw here after dispose, skipping the
      // subscription below; keep that outcome.
      if (_disposed) return;
      _isAudioStreaming = true;
      notifyListeners();

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isAudioStreaming || !_live.hasSession || !_isConnected) return;

        // Calculate audio peak for volume VU meter
        if (chunk.length >= 2) {
          final byteData = ByteData.sublistView(chunk);
          var peak = 0;
          for (var i = 0; i < chunk.length - 1; i += 2) {
            final sample = byteData.getInt16(i, Endian.little).abs();
            if (sample > peak) peak = sample;
          }
          final norm = (peak / 32768.0).clamp(0.0, 1.0);
          if (!_disposed) {
            audioVolume.value = (audioVolume.value * 0.3) + (norm * 0.7);
          }
        }

        // Send 16kHz PCM blob to Gemini Live
        _live.sendAudioChunk(chunk);
      });
    } catch (e) {
      _notice('오디오 스트리밍 시작 오류: $e', MediaSubtitleNoticeKind.plain);
    }
  }

  Future<void> disconnect() async {
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _mic.stop();
    _live.closeAndClear();
    if (!_disposed) {
      _isConnected = false;
      _isConnecting = false;
      _isAudioStreaming = false;
      audioVolume.value = 0.0;
      notifyListeners();
    }
  }

  void copySubtitlesToClipboard() {
    if (_subtitleHistory.isEmpty) {
      _notice('복사할 자막 기록이 없습니다.', MediaSubtitleNoticeKind.plain);
      return;
    }
    _clipboard.copy(buildSubtitleTranscript(_subtitleHistory));
    _notice('전체 자막이 클립보드에 복사되었습니다.', MediaSubtitleNoticeKind.plain);
  }

  void clearSubtitles() {
    _subtitleHistory.clear();
    _currentOriginalSubtitle = '';
    _currentTranslatedSubtitle = '';
    _usageTracker.reset();
    _bumpSubtitles();
    notifyListeners();
  }
}
