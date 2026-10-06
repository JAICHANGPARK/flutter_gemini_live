import 'package:gemini_live/gemini_live.dart';

/// Wraps the Lyria RealTime WebSocket session.
class DjMusicService {
  LiveMusicSession? _session;

  bool get hasSession => _session != null;

  /// Opens a Lyria RealTime connection. Does not store the session; the
  /// caller decides when to [attach] it.
  Future<LiveMusicSession> connect({
    required String apiKey,
    required LiveMusicCallbacks callbacks,
  }) async {
    final musicService = LiveMusicService(
      apiKey: apiKey,
      apiVersion: 'v1alpha',
    );

    return musicService.connect(
      LiveMusicConnectParameters(
        model: LiveMusicModels.lyriaRealtimeExp,
        callbacks: callbacks,
      ),
    );
  }

  void attach(LiveMusicSession session) => _session = session;

  void play() => _session?.play();

  void pause() => _session?.pause();

  /// Fire-and-forget close (the session callbacks report the result).
  void close() => _session?.close();

  void setWeightedPrompts(List<WeightedPrompt> prompts) =>
      _session!.setWeightedPrompts(prompts);

  void setMusicGenerationConfig(LiveMusicGenerationConfig config) =>
      _session!.setMusicGenerationConfig(config);
}
