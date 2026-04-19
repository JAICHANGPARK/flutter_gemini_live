import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum Role { user, model }

class ChatAudioClip {
  ChatAudioClip.wav({
    required this.wavBytes,
    required this.waveform,
    required this.mimeType,
    this.autoPlay = false,
    this.label = 'Voice response',
  }) : filePath = null;

  ChatAudioClip.file({
    required this.filePath,
    this.mimeType = 'audio/m4a',
    List<double>? waveform,
    this.autoPlay = false,
    this.label = 'Voice message',
  }) : wavBytes = null,
       waveform = waveform ?? _defaultWaveform();

  final Uint8List? wavBytes;
  final String? filePath;
  final List<double> waveform;
  final String mimeType;
  final bool autoPlay;
  final String label;

  static List<double> _defaultWaveform() {
    return const [
      0.18,
      0.32,
      0.46,
      0.28,
      0.62,
      0.35,
      0.52,
      0.26,
      0.58,
      0.38,
      0.48,
      0.24,
      0.54,
      0.42,
      0.33,
      0.56,
      0.29,
      0.45,
      0.22,
      0.36,
    ];
  }
}

class ChatMessage {
  static int _nextId = 0;

  final String id;
  final String text;
  final Role author;
  final XFile? image;
  final ChatAudioClip? audio;

  ChatMessage({
    required this.text,
    required this.author,
    this.image,
    this.audio,
    String? id,
  }) : id = id ?? 'chat_message_${_nextId++}';

  ChatMessage copyWith({
    String? text,
    Role? author,
    XFile? image,
    ChatAudioClip? audio,
    bool clearImage = false,
    bool clearAudio = false,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      image: clearImage ? null : (image ?? this.image),
      audio: clearAudio ? null : (audio ?? this.audio),
    );
  }
}
