/// Pure-Dart entry point for the `gemini_live` package.
///
/// Use this library in pure Dart CLI, server, or background isolate environments
/// where Flutter (`dart:ui`) is not required.
library;

export 'src/auth_tokens_service.dart';
export 'src/google_genai.dart';
export 'src/music_service.dart';
export 'src/utils/audio_utils.dart';
export 'src/utils/frame_rate_limiter.dart';
export 'src/utils/function_tool_registry.dart';
export 'src/utils/pcm_audio_buffer.dart';
export 'src/utils/reconnect_policy.dart';
export 'src/utils/wav_header.dart';
export 'src/voices_service.dart';
