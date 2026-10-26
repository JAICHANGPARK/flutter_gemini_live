import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../data/services/function_calling_audio_service.dart';
import '../../../data/services/function_calling_live_service.dart';
import '../../../domain/mock_function_executor.dart';
import '../../../domain/models/chat_message.dart';
import '../function_calling_i18n.dart';

/// State + logic for the function calling (tool calling) demo screen.
class FunctionCallingViewModel extends ChangeNotifier {
  FunctionCallingViewModel({
    FunctionCallingLiveService? liveService,
    FunctionCallingAudioService? audioService,
    MockFunctionExecutor? executor,
  }) : _live = liveService ?? FunctionCallingLiveService(),
       _audio = audioService ?? FunctionCallingAudioService(),
       _executor = executor ?? const MockFunctionExecutor();

  final FunctionCallingLiveService _live;
  final FunctionCallingAudioService _audio;
  final MockFunctionExecutor _executor;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _toolsEnabled = true;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get toolsEnabled => _toolsEnabled;

  final List<ChatMessage> _messages = [];
  final List<FunctionCall> _pendingFunctionCalls = [];

  List<ChatMessage> get messages => _messages;
  List<FunctionCall> get pendingFunctionCalls => _pendingFunctionCalls;

  @override
  void dispose() {
    _disposed = true;
    _live.close();
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _addSystemMessage(FunctionCallingI18n.current.sysApiKeyNotConfigured);
      return;
    }

    _isConnecting = true;
    notifyListeners();
    _addSystemMessage(FunctionCallingI18n.current.sysConnecting);
    await _audio.stop();

    try {
      final session = await _live.connect(
        onOpen: () {
          _addSystemMessage(FunctionCallingI18n.current.sysConnected);
          _isConnected = true;
          _isConnecting = false;
          notifyListeners();
        },
        onMessage: _handleMessage,
        onError: (error, stack) {
          unawaited(_audio.stop());
          _addSystemMessage(FunctionCallingI18n.current.sysError(error));
          _isConnecting = false;
          notifyListeners();
        },
        onClose: (code, reason) {
          unawaited(_audio.stop());
          _addSystemMessage(FunctionCallingI18n.current.sysConnectionClosed);
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
        },
      );

      _live.attach(session);
      notifyListeners();
    } catch (e) {
      _addSystemMessage(FunctionCallingI18n.current.sysConnectionFailed(e));
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _handleMessage(LiveServerMessage message) {
    final serverContent = message.serverContent;
    final turnFinished =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (serverContent?.interrupted ?? false) {
      _audio.clear();
    }

    // Handle text response
    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      _addMessage('model', textChunk);
    }

    if (message.data != null) {
      _audio.appendBase64Chunk(message.data!);
      _addSystemMessage(FunctionCallingI18n.current.sysReceivedAudio);
    }

    // Handle tool calls
    if (message.toolCall != null) {
      final calls = message.toolCall!.functionCalls ?? [];
      for (final call in calls) {
        _handleFunctionCall(call);
      }
    }

    // Handle tool call cancellation
    if (message.toolCallCancellation != null) {
      final ids = message.toolCallCancellation!.ids ?? [];
      _addSystemMessage(
        FunctionCallingI18n.current.sysToolCallsCancelled(ids.join(", ")),
      );
      _pendingFunctionCalls.removeWhere((call) => ids.contains(call.id));
      notifyListeners();
    }

    if (turnFinished && _audio.hasBufferedAudio) {
      _addSystemMessage(FunctionCallingI18n.current.sysPlayingAudio);
      unawaited(_audio.playBufferedAudio());
    }
  }

  void _handleFunctionCall(FunctionCall call) {
    _addSystemMessage(
      FunctionCallingI18n.current.sysFunctionCall(call.name, call.id),
    );
    _addSystemMessage(FunctionCallingI18n.current.sysFunctionArgs(call.args));

    _pendingFunctionCalls.add(call);
    notifyListeners();

    // Simulate function execution
    // In production, you would actually call your functions here
    final executed = _executor.execute(call);
    final result = executed.result;
    final scheduling = executed.scheduling;

    _addSystemMessage(FunctionCallingI18n.current.sysSendingResponse(result));

    // Send function response
    _live.sendToolResponse(call, result, scheduling);

    _pendingFunctionCalls.removeWhere((c) => c.id == call.id);
    notifyListeners();
  }

  void _addMessage(String author, String text) {
    _messages.add(
      ChatMessage(author: author, text: text, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  void _addSystemMessage(String text) {
    _messages.add(
      ChatMessage(
        author: 'system',
        text: text,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    );
    notifyListeners();
  }

  void sendText(String text) {
    if (!_live.hasSession || !_isConnected) {
      _addSystemMessage(FunctionCallingI18n.current.sysNotConnected);
      return;
    }

    _addMessage('user', text);
    _live.sendText(text);
  }

  /// Dynamically clears or restores session tools via `sendContextUpdate`.
  void toggleToolsInSession() {
    if (!_live.hasSession || !_isConnected) return;
    _toolsEnabled = !_toolsEnabled;
    _live.updateTools(enabled: _toolsEnabled);
    _addSystemMessage(
      _toolsEnabled
          ? FunctionCallingI18n.current.sysToolsReEnabled
          : FunctionCallingI18n.current.sysToolsCleared,
    );
    notifyListeners();
  }
}
