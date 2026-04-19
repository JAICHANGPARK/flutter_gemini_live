import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'message.dart';

Future<Source> createLiveAudioSource(Uint8List wavBytes) async {
  return BytesSource(wavBytes, mimeType: 'audio/wav');
}

Future<Source> createChatAudioSource(ChatAudioClip clip) async {
  if (clip.wavBytes != null) {
    return BytesSource(clip.wavBytes!, mimeType: clip.mimeType);
  }
  final filePath = clip.filePath;
  if (filePath == null) {
    throw ArgumentError('Audio clip does not contain playback data.');
  }
  return UrlSource(filePath, mimeType: clip.mimeType);
}
