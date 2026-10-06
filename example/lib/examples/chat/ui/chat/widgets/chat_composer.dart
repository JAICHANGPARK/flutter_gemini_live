import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../view_models/chat_view_model.dart';

/// Builds the text input composer with buttons for image, audio, and sending.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.viewModel,
    required this.textController,
    required this.onSend,
  });

  final ChatViewModel viewModel;
  final TextEditingController textController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final pickedImage = vm.pickedImage;
    final pickedImageBytes = vm.pickedImageBytes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (vm.voiceModeEnabled)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    vm.isRecording ? Icons.mic : Icons.keyboard_voice,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.isRecording
                          ? 'Recording voice input... tap the mic again to send it.'
                          : 'Voice mode is ready. Tap the mic to record spoken input.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          // Show a preview of the picked image.
          if (pickedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes, fit: BoxFit.cover)
                          : FutureBuilder<Uint8List>(
                              future: pickedImage.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      // Button to remove the selected image.
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                        onPressed: vm.clearPickedImage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              // Button to pick an image.
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: vm.pickImage,
              ),
              // Button to toggle audio recording.
              if (vm.voiceModeEnabled)
                GeminiLiveMicButton(
                  isRecording: vm.isRecording,
                  onPressed: vm.toggleRecording,
                  tooltip: vm.isRecording ? 'Stop recording' : 'Record voice',
                ),
              // The main text input field.
              Expanded(
                child: TextField(
                  controller: textController,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration.collapsed(
                    hintText: vm.voiceModeEnabled
                        ? 'Type a message or use the mic'
                        : 'Enter a message or image description',
                  ),
                ),
              ),
              // Button to send the message.
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: onSend,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
