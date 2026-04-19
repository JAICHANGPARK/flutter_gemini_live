import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'message.dart';

Future<Source> createLiveAudioSource(Uint8List wavBytes) async {
  final tempDir = await getTemporaryDirectory();
  await tempDir.create(recursive: true);

  final audioDir = Directory('${tempDir.path}/gemini_live_audio');
  await audioDir.create(recursive: true);

  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final file = File('${audioDir.path}/response_$timestamp.wav');
  await file.writeAsBytes(wavBytes, flush: true);
  return DeviceFileSource(file.path, mimeType: 'audio/wav');
}

Future<Source> createChatAudioSource(ChatAudioClip clip) async {
  if (clip.wavBytes != null) {
    return createLiveAudioSource(clip.wavBytes!);
  }
  final filePath = clip.filePath;
  if (filePath == null) {
    throw ArgumentError('Audio clip does not contain playback data.');
  }
  return DeviceFileSource(filePath, mimeType: clip.mimeType);
}
