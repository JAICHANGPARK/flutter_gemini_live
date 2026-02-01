import 'dart:io';
import 'package:gemini_live/gemini_live.dart';

/// Example: Realtime Audio and Video Input
///
/// This example demonstrates how to send realtime audio and video input
/// to the Gemini Live API.
void main() async {
  const apiKey = 'YOUR_API_KEY'; // Replace with your actual API key

  final liveService = LiveService(apiKey: apiKey, apiVersion: 'v1beta');

  final session = await liveService.connect(
    LiveConnectParameters(
      model: 'gemini-live-2.5-flash-preview',
      callbacks: LiveCallbacks(
        onOpen: () {
          print('✅ Connected to Live API');
        },
        onMessage: (message) {
          _handleMessage(message);
        },
        onError: (error, stackTrace) {
          print('❌ Error: $error');
        },
        onClose: (code, reason) {
          print('🔒 Connection closed');
        },
      ),
      config: GenerationConfig(
        temperature: 0.7,
        responseModalities: [Modality.AUDIO, Modality.TEXT],
      ),
      // Enable audio transcription
      inputAudioTranscription: AudioTranscriptionConfig(),
      outputAudioTranscription: AudioTranscriptionConfig(),
      // Configure realtime input with automatic activity detection
      realtimeInputConfig: RealtimeInputConfig(
        automaticActivityDetection: AutomaticActivityDetection(
          disabled: false,
          startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
          endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
          prefixPaddingMs: 300,
          silenceDurationMs: 500,
        ),
        activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
        turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
      ),
    ),
  );

  print('🎙️ Starting realtime audio input...');

  // Simulate sending audio chunks
  // In a real app, you would read from microphone
  await _simulateAudioStream(session);

  // Simulate sending video frames
  print('📹 Sending video frames...');
  await _simulateVideoStream(session);

  await Future.delayed(Duration(seconds: 5));
  await session.close();
  print('👋 Session closed');
}

Future<void> _simulateAudioStream(LiveSession session) async {
  // In a real app, you would:
  // 1. Read audio chunks from microphone
  // 2. Encode them as base64
  // 3. Send them via sendAudio() or sendRealtimeInput()

  for (int i = 0; i < 5; i++) {
    // Simulate audio chunk
    final audioChunk = List<int>.generate(320, (index) => index % 256);

    // Send as audio
    session.sendAudio(audioChunk);

    print('🔊 Sent audio chunk ${i + 1}/5');
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Signal end of audio stream
  session.sendAudioStreamEnd();
  print('🔇 Audio stream ended');
}

Future<void> _simulateVideoStream(LiveSession session) async {
  // In a real app, you would:
  // 1. Capture frames from camera
  // 2. Encode them as JPEG/PNG
  // 3. Send them via sendVideo() or sendRealtimeInput()

  for (int i = 0; i < 3; i++) {
    // Simulate video frame
    final frame = List<int>.generate(1000, (index) => index % 256);

    // Send video frame
    session.sendVideo(frame, mimeType: 'image/jpeg');

    print('📸 Sent video frame ${i + 1}/3');
    await Future.delayed(Duration(milliseconds: 500));
  }
}

void _handleMessage(LiveServerMessage message) {
  // Handle text response
  if (message.text != null) {
    print('🤖 Model: ${message.text}');
  }

  // Handle audio data
  if (message.data != null) {
    print('🔊 Received audio: ${message.data!.length} chars');
  }

  // Handle transcriptions
  if (message.serverContent?.inputTranscription != null) {
    final transcription = message.serverContent!.inputTranscription!;
    print(
      '🎤 Input transcription: ${transcription.text} ' +
          '(finished: ${transcription.finished})',
    );
  }

  if (message.serverContent?.outputTranscription != null) {
    final transcription = message.serverContent!.outputTranscription!;
    print(
      '🔈 Output transcription: ${transcription.text} ' +
          '(finished: ${transcription.finished})',
    );
  }

  // Handle voice activity
  if (message.voiceActivity != null) {
    print(
      '🎤 Voice activity: speechActive=${message.voiceActivity!.speechActive}',
    );
  }

  // Handle voice activity detection signal
  if (message.voiceActivityDetectionSignal != null) {
    final signal = message.voiceActivityDetectionSignal!;
    if (signal.start == true) {
      print('🎙️ Speech started');
    }
    if (signal.end == true) {
      print('🎙️ Speech ended');
    }
  }
}
