import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Wraps the Lyria Live (`BidiGenerateMusic`) client.
class MusicStudioLiveService {
  LiveMusicService? _musicService;

  Future<LiveMusicSession> connect({
    required String apiKey,
    required String model,
    required LiveMusicCallbacks callbacks,
  }) async {
    _musicService = LiveMusicService(
      apiKey: apiKey,
      apiVersion: 'v1alpha',
      logger: (msg) => debugPrint('[LiveMusic] $msg'),
    );

    return _musicService!.connect(
      LiveMusicConnectParameters(model: model, callbacks: callbacks),
    );
  }
}
