import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

import 'live_audio_source_io.dart'
    if (dart.library.js_interop) 'live_audio_source_web.dart';
import 'message.dart';

class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.author == Role.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: message.author == Role.user
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(32.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          File(message.image!.path),
                          height: 150,
                        ),
                      ),
                    ),
                  if (message.audio != null)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: message.text.isNotEmpty ? 10.0 : 0,
                      ),
                      child: _AudioMessageCard(
                        audio: message.audio!,
                        isUser: message.author == Role.user,
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: _buildMarkdownStyleSheet(
                        context,
                        isUser: message.author == Role.user,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _buildMarkdownStyleSheet(
  BuildContext context, {
  required bool isUser,
}) {
  final theme = Theme.of(context);
  final textColor = isUser
      ? theme.colorScheme.onPrimaryContainer
      : theme.colorScheme.onSecondaryContainer;
  final baseTextStyle =
      theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.45) ??
      TextStyle(color: textColor, height: 1.45);
  final codeBackground = textColor.withValues(alpha: 0.08);
  final blockquoteBackground = textColor.withValues(alpha: 0.08);

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: baseTextStyle,
    code: baseTextStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: codeBackground,
      fontSize: (baseTextStyle.fontSize ?? 14) * 0.92,
    ),
    a: baseTextStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    ),
    h1: theme.textTheme.headlineSmall?.copyWith(color: textColor),
    h2: theme.textTheme.titleLarge?.copyWith(color: textColor),
    h3: theme.textTheme.titleMedium?.copyWith(color: textColor),
    h4: theme.textTheme.bodyLarge?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    ),
    h5: theme.textTheme.bodyLarge?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    ),
    h6: theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    ),
    em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
    strong: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
    blockquote: baseTextStyle,
    listBullet: baseTextStyle,
    tableHead: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
    tableBody: baseTextStyle,
    blockquoteDecoration: BoxDecoration(
      color: blockquoteBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border(
        left: BorderSide(color: textColor.withValues(alpha: 0.25), width: 4),
      ),
    ),
    codeblockDecoration: BoxDecoration(
      color: codeBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: textColor.withValues(alpha: 0.18), width: 1),
      ),
    ),
  );
}

class _AudioMessageCard extends StatefulWidget {
  const _AudioMessageCard({required this.audio, required this.isUser});

  final ChatAudioClip audio;
  final bool isUser;

  @override
  State<_AudioMessageCard> createState() => _AudioMessageCardState();
}

class _AudioMessageCardState extends State<_AudioMessageCard> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  bool _hasAutoplayed = false;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _position = _duration;
        _state = PlayerState.completed;
      });
    });

    if (widget.audio.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasAutoplayed) return;
        _hasAutoplayed = true;
        _togglePlayback();
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPreparing) return;

    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }

    if (_state == PlayerState.paused) {
      await _player.resume();
      return;
    }

    if (_state == PlayerState.completed) {
      await _startPlayback(fromStart: true);
      return;
    }

    await _startPlayback(fromStart: _duration > Duration.zero);
  }

  Future<void> _startPlayback({required bool fromStart}) async {
    setState(() {
      _isPreparing = true;
      if (fromStart) {
        _position = Duration.zero;
      }
    });

    try {
      await _player.stop();
      final source = await createChatAudioSource(widget.audio);
      await _player.play(source);
    } catch (error) {
      debugPrint('Audio bubble playback failed: $error');
    }

    if (!mounted) return;
    setState(() => _isPreparing = false);
  }

  String get _statusLabel {
    switch (_state) {
      case PlayerState.playing:
        return 'Playing';
      case PlayerState.paused:
        return 'Paused';
      case PlayerState.completed:
        return 'Replay';
      case PlayerState.stopped:
        return _isPreparing
            ? 'Loading'
            : (widget.audio.autoPlay ? 'Ready' : 'Play');
      case PlayerState.disposed:
        return 'Play';
    }
  }

  IconData get _statusIcon {
    switch (_state) {
      case PlayerState.playing:
        return Icons.pause_circle_filled;
      case PlayerState.paused:
      case PlayerState.stopped:
      case PlayerState.completed:
      case PlayerState.disposed:
        return _isPreparing ? Icons.hourglass_top : Icons.play_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : (_state == PlayerState.completed ? 1.0 : 0.0);
    final activeColor = widget.isUser
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.primary;
    final inactiveColor = activeColor.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _togglePlayback,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(_statusIcon, color: activeColor, size: 28),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.audio.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    _statusLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: inactiveColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < widget.audio.waveform.length; i++)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: WaveFormBar(
                        amplitude: _toWaveAmplitude(widget.audio.waveform[i]),
                        maxHeight: 12,
                        color: i / widget.audio.waveform.length <= progress
                            ? activeColor
                            : inactiveColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Amplitude _toWaveAmplitude(double normalized) {
  final safeValue = normalized.clamp(0.0, 1.0);
  final translated = 1 + ((1 - safeValue) * 159);
  return Amplitude(current: translated, max: 160);
}
