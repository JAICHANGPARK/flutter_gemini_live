import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin: file-based voice input recording.
class ChatRecorderService {
  final AudioRecorder _audioRecorder =
      AudioRecorder(); // The main object for handling audio recording.

  Stream<RecordState> onStateChanged() => _audioRecorder.onStateChanged();

  Future<bool> hasPermission() => _audioRecorder.hasPermission();

  Future<String?> stop() => _audioRecorder.stop();

  Future<List<InputDevice>> listInputDevices() =>
      _audioRecorder.listInputDevices();

  /// Builds the output file path for a new recording (empty on web).
  Future<String> createRecordingPath() async {
    String filePath = '';
    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      final recordingsDir = Directory('${tempDir.path}/gemini_live_recordings');
      await recordingsDir.create(recursive: true);
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      filePath = '${recordingsDir.path}/input_$timestamp.m4a';
    }
    return filePath;
  }

  /// Starts recording with a configuration that matches the MIME type.
  Future<void> start({InputDevice? device, required String path}) {
    return _audioRecorder.start(
      kIsWeb
          ? RecordConfig(encoder: AudioEncoder.wav, device: device)
          : RecordConfig(encoder: AudioEncoder.aacLc, device: device),
      path: path,
    );
  }

  /// Reads the recorded audio file as bytes.
  Future<Uint8List> readRecordedBytes(String path) async {
    final Uint8List audioBytes;
    if (kIsWeb) {
      final response = await http.get(Uri.parse(path));
      audioBytes = response.bodyBytes;
    } else {
      final file = File(path);
      audioBytes = await file.readAsBytes();
    }
    return audioBytes;
  }

  void dispose() {
    _audioRecorder.dispose(); // Dispose of the audio recorder.
  }
}
