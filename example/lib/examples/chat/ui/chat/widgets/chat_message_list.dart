import 'package:example/bubble.dart';
import 'package:flutter/material.dart';

import '../view_models/chat_view_model.dart';

/// The main chat area (newest message at the bottom).
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key, required this.viewModel});

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final messages = vm.messages;
    final streamingMessage = vm.streamingMessage;
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      reverse: true, // Shows the latest messages at the bottom.
      // The item count includes the streaming message if it exists.
      itemCount: messages.length + (streamingMessage == null ? 0 : 1),
      itemBuilder: (context, index) {
        // If there's a streaming message, render it at the top (index 0).
        if (streamingMessage != null && index == 0) {
          return Bubble(
            key: ValueKey(streamingMessage.id),
            message: streamingMessage,
            playbackCommand: vm.audioPlaybackCommand,
            activeAudioMessageId: vm.activeAudioMessageId,
            shouldAutoPlay: vm.autoplayAudioMessageId == streamingMessage.id,
            onPlaybackRequested: vm.requestBubblePlayback,
            onAutoPlayHandled: vm.clearAutoPlayRequest,
          );
        }
        // Adjust the index to access the main messages list.
        final messageIndex = index - (streamingMessage == null ? 0 : 1);
        final message = messages.reversed.toList()[messageIndex];
        return Bubble(
          key: ValueKey(message.id),
          message: message,
          playbackCommand: vm.audioPlaybackCommand,
          activeAudioMessageId: vm.activeAudioMessageId,
          shouldAutoPlay: vm.autoplayAudioMessageId == message.id,
          onPlaybackRequested: vm.requestBubblePlayback,
          onAutoPlayHandled: vm.clearAutoPlayRequest,
        );
      },
    );
  }
}
