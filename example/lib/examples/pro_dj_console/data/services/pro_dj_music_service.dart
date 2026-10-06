import 'package:example/api_key_store.dart';
import 'package:gemini_live/gemini_live.dart';

/// Wraps the Lyria RealTime (`LiveMusicService`) WebSocket session.
class ProDjMusicService {
  LiveMusicSession? _session;

  bool get hasSession => _session != null;

  /// Opens a Lyria RealTime session. The session is not stored until
  /// [attach] is called (so a caller can discard it if it was disposed
  /// while connecting).
  Future<LiveMusicSession> connect(LiveMusicCallbacks callbacks) {
    final musicService = LiveMusicService(
      apiKey: ApiKeyStore.apiKey,
      apiVersion: 'v1alpha',
    );

    return musicService.connect(
      LiveMusicConnectParameters(
        model: LiveMusicModels.lyriaRealtimeExp,
        callbacks: callbacks,
      ),
    );
  }

  void attach(LiveMusicSession session) {
    _session = session;
  }

  void play() => _session!.play();

  void pause() => _session!.pause();

  void stop() => _session!.stop();

  void resetContext() => _session!.resetContext();

  void setWeightedPrompts(List<WeightedPrompt> prompts) =>
      _session!.setWeightedPrompts(prompts);

  void setMusicGenerationConfig(LiveMusicGenerationConfig config) =>
      _session!.setMusicGenerationConfig(config);

  void close() {
    _session?.close();
  }
}
