/// Public entry point for the `gemini_live` package.
///
/// Import this library to access the high-level [GoogleGenAI] client,
/// Live API session helpers, and the package's request and response models.
library;

export 'src/google_genai.dart';
export 'src/utils/wav_header.dart';
export 'src/widgets/live_status_badge.dart';
export 'src/widgets/live_mic_button.dart';
export 'src/widgets/live_voice_indicator.dart';
export 'src/utils/token_usage_tracker.dart';
export 'src/widgets/live_usage_badge.dart';
export 'src/voices_service.dart';
export 'src/utils/audio_utils.dart';
export 'src/utils/live_session_controller.dart';
export 'src/widgets/live_waveform.dart';
export 'src/widgets/live_caption_bubble.dart';
export 'src/music_service.dart';
export 'src/auth_tokens_service.dart';
