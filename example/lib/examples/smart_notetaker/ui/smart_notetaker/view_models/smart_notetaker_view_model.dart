import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../../data/repositories/audio_device_repository.dart';
import '../../../data/services/smart_notetaker_live_service.dart';
import '../../../data/services/smart_notetaker_mic_service.dart';
import '../../../domain/models/live_speech_turn.dart';
import '../../../domain/models/note_action_item.dart';
import '../../../domain/models/note_language.dart';
import '../../../domain/note_chunk_parser.dart';
import '../../../domain/note_prompts.dart';

/// State + logic for the Live Smart NoteTaker screen.
///
/// Coarse state notifies through [ChangeNotifier]; the high-frequency mic level
/// lives on [audioVolumeNotifier]. The view model never touches a
/// `BuildContext`; it asks the view for things via [onNotice] and
/// [requestApiKeySetup].
class SmartNotetakerViewModel extends ChangeNotifier {
  SmartNotetakerViewModel({
    SmartNotetakerLiveService? liveService,
    SmartNotetakerMicService? micService,
    AudioDeviceRepository? audioDeviceRepository,
  }) : _live = liveService ?? SmartNotetakerLiveService(),
       _mic = micService ?? SmartNotetakerMicService(),
       _audioDeviceRepo = audioDeviceRepository ?? AudioDeviceRepository();

  final SmartNotetakerLiveService _live;
  final SmartNotetakerMicService _mic;
  final AudioDeviceRepository _audioDeviceRepo;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(String message)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _notice(String message) {
    if (_disposed) return;
    onNotice?.call(message);
  }

  final ScrollController timelineScrollController = ScrollController();
  final ScrollController noteScrollController = ScrollController();

  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Session state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isRecording = false;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // Session timer
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  // Target translation language
  String _targetLanguageCode = 'ko';
  String get targetLanguageCode => _targetLanguageCode;
  set targetLanguageCode(String code) {
    _targetLanguageCode = code;
    notifyListeners();
  }

  // Live Speech Feed
  String _interimSpeech = '';
  final List<LiveSpeechTurn> _speechTurns = [];
  String get interimSpeech => _interimSpeech;
  List<LiveSpeechTurn> get speechTurns => _speechTurns;

  // Smart Notes
  final StringBuffer _rawNotesBuffer = StringBuffer();
  final List<String> _keyTakeaways = [];
  final List<NoteActionItem> _actionItems = [];
  final List<String> _glossaryTerms = [];
  String get rawNotes => _rawNotesBuffer.toString();
  List<String> get keyTakeaways => _keyTakeaways;
  List<NoteActionItem> get actionItems => _actionItems;

  // Audio level (high-frequency, kept off notifyListeners)
  final ValueNotifier<double> audioVolumeNotifier = ValueNotifier(0.0);
  double _audioVolume = 0.0;
  InputDevice? _selectedAudioDevice;
  List<InputDevice> _availableAudioDevices = [];
  InputDevice? get selectedAudioDevice => _selectedAudioDevice;
  List<InputDevice> get availableAudioDevices => _availableAudioDevices;

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: 'gemini-3.1-flash-live-preview',
  );
  GeminiTokenUsageTracker get usageTracker => _usageTracker;

  // Active Tab for Mobile / Split View
  int _activeViewTab = 0; // 0: Timeline, 1: Smart Notes, 2: Action Items
  int get activeViewTab => _activeViewTab;
  set activeViewTab(int tab) {
    _activeViewTab = tab;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void init() {
    _loadAudioDevices();
    _appendInitialNoteGuide();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionTimer?.cancel();
    _audioStreamSubscription?.cancel();
    unawaited(_mic.dispose());
    _live.close();
    timelineScrollController.dispose();
    noteScrollController.dispose();
    _usageTracker.dispose();
    audioVolumeNotifier.dispose();
    super.dispose();
  }

  void _appendInitialNoteGuide() {
    writeInitialNoteGuide(_rawNotesBuffer);
  }

  // ---------------------------------------------------------------------------
  // Audio devices
  // ---------------------------------------------------------------------------

  Future<void> loadAudioDevices() => _loadAudioDevices();

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await _mic.listInputDevices();
      if (!_disposed) {
        _availableAudioDevices = devices;
        final savedId = _audioDeviceRepo.savedDeviceId;
        if (savedId.isNotEmpty) {
          _selectedAudioDevice = devices
              .where((d) => d.id == savedId)
              .firstOrNull;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Selects the device with [deviceId] (or the system default when
  /// `'__default__'`).
  void selectAudioDeviceById(String deviceId) {
    if (deviceId == '__default__') {
      switchAudioDevice(null);
    } else {
      final dev = _availableAudioDevices
          .where((d) => d.id == deviceId)
          .firstOrNull;
      switchAudioDevice(dev);
    }
  }

  Future<void> switchAudioDevice(InputDevice? device) async {
    if (_selectedAudioDevice?.id == device?.id) return;
    _selectedAudioDevice = device;
    notifyListeners();
    await _audioDeviceRepo.save(device?.id ?? '', device?.label ?? '');

    if (_isRecording) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _mic.stop();
      } catch (_) {}
      _isRecording = false;
      if (!_disposed) {
        await _startAudioRecording();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String formatElapsedTime() {
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

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  Future<void> toggleSession() async {
    if (_isConnected) {
      await _stopSession();
    } else {
      await _startSession();
    }
  }

  Future<void> _startSession() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !ApiKeyStore.hasApiKey) {
        _notice('Gemini API 키가 설정되지 않았습니다.');
        return;
      }
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final targetLang = _getTargetLanguageName();

      await _live.connect(
        targetLang: targetLang,
        onOpen: () {
          debugPrint('[GeminiLive Note] 🌐 onOpen received');
        },
        onMessage: (message) {
          if (_disposed) return;
          _handleLiveMessage(message);
        },
        onError: (err, _) {
          debugPrint('[GeminiLive Note] ❌ onError: $err');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
          _notice('Live 세션 오류: $err');
        },
        onClose: (code, reason) {
          debugPrint(
            '[GeminiLive Note] 🔒 onClose (code: $code, reason: $reason)',
          );
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          _isRecording = false;
          notifyListeners();
          _sessionTimer?.cancel();
          if (reason != null && reason.isNotEmpty) {
            _notice('세션 종료 ($code): $reason');
          }
        },
      );

      if (!_disposed) {
        _isConnected = true;
        _isConnecting = false;
        _elapsedSeconds = 0;
        notifyListeners();
        _startSessionTimer();
        await _startAudioRecording();
      }
    } catch (e) {
      debugPrint('[GeminiLive Note] 🚨 Connection failed: $e');
      if (!_disposed) {
        _isConnecting = false;
        notifyListeners();
        _notice('세션 시작 실패: $e');
      }
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) {
        _elapsedSeconds++;
        notifyListeners();
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
      _interimSpeech = speakerText.trim();
      notifyListeners();
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
        _speechTurns.add(
          LiveSpeechTurn(
            speakerText: _interimSpeech,
            translatedText: noteChunk,
          ),
        );
        _interimSpeech = '';
        notifyListeners();

        // Scroll timeline to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (timelineScrollController.hasClients) {
            timelineScrollController.animateTo(
              timelineScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _processNoteChunk(String chunk) {
    _rawNotesBuffer.write(chunk);
    _rawNotesBuffer.writeln();

    // Parse structured tags in real-time
    parseNoteChunkTags(
      chunk,
      keyTakeaways: _keyTakeaways,
      actionItems: _actionItems,
      glossaryTerms: _glossaryTerms,
    );
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteScrollController.hasClients) {
        noteScrollController.animateTo(
          noteScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startAudioRecording() async {
    if (_isRecording) return;

    final hasPermission = await _mic.hasPermission();
    if (!hasPermission) {
      _notice('마이크 권한이 필요합니다.');
      return;
    }

    try {
      final stream = await _mic.startStream(device: _selectedAudioDevice);

      _isRecording = true;
      notifyListeners();

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isRecording || !_live.hasSession || !_isConnected) return;

        // Calculate audio volume peak
        if (chunk.length >= 2) {
          final byteData = ByteData.sublistView(chunk);
          var peak = 0;
          for (var i = 0; i < chunk.length - 1; i += 2) {
            final sample = byteData.getInt16(i, Endian.little).abs();
            if (sample > peak) peak = sample;
          }
          final norm = (peak / 32768.0).clamp(0.0, 1.0);
          if (!_disposed) {
            _audioVolume = (_audioVolume * 0.3) + (norm * 0.7);
            audioVolumeNotifier.value = _audioVolume;
          }
        }

        // Send PCM chunk
        _live.sendAudioChunk(chunk);
      });
    } catch (e) {
      _notice('오디오 녹음 시작 오류: $e');
    }
  }

  Future<void> _stopSession() async {
    _sessionTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _mic.stop();
    _live.close();
    if (!_disposed) {
      _isConnected = false;
      _isConnecting = false;
      _isRecording = false;
      _audioVolume = 0.0;
      audioVolumeNotifier.value = _audioVolume;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Notes actions
  // ---------------------------------------------------------------------------

  void generateWrapUpSummary() {
    if (_speechTurns.isEmpty && _rawNotesBuffer.isEmpty) {
      _notice('요약할 회의/강의 내용이 없습니다.');
      return;
    }

    if (_live.hasSession && _isConnected) {
      _live.sendWrapUpRequest();
      _notice('AI에게 최종 요약 정리를 요청했습니다...');
    }
  }

  void copyNotesToClipboard() {
    final fullText = _rawNotesBuffer.toString();
    if (fullText.isEmpty) {
      _notice('복사할 노트 내용이 없습니다.');
      return;
    }
    Clipboard.setData(ClipboardData(text: fullText));
    _notice('스마트 마크다운 노트가 클립보드에 복사되었습니다!');
  }

  void clearNotes() {
    _speechTurns.clear();
    _rawNotesBuffer.clear();
    _keyTakeaways.clear();
    _actionItems.clear();
    _glossaryTerms.clear();
    _interimSpeech = '';
    _elapsedSeconds = 0;
    _usageTracker.reset();
    _appendInitialNoteGuide();
    notifyListeners();
  }

  void setActionItemCompleted(NoteActionItem item, bool? value) {
    item.isCompleted = value ?? false;
    notifyListeners();
  }
}
