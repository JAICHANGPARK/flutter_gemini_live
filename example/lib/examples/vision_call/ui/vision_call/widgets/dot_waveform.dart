import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/audio_activity.dart';

/// Animated horizontal dots (••••••••••••••) responding to speech / AI response
class DotWaveform extends StatelessWidget {
  const DotWaveform({
    super.key,
    required this.animation,
    required this.audioActivity,
  });

  final AnimationController animation;
  final ValueNotifier<AudioActivity> audioActivity;

  @override
  Widget build(BuildContext context) {
    const dotCount = 14;

    return AnimatedBuilder(
      animation: Listenable.merge([animation, audioActivity]),
      builder: (context, child) {
        final animValue = animation.value * 2 * math.pi;
        final act = audioActivity.value;
        final isUserSpeaking = act.isUserSpeaking || act.userMicVolume > 0.015;
        final isAiActive = act.isAiResponding;
        final isActive = isAiActive || isUserSpeaking;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
            // Wave calculation
            final wave = math.sin(animValue + (i * 0.45));
            const baseHeight = 4.0;
            final dynamicHeight = isActive
                ? (isUserSpeaking
                      ? (baseHeight +
                            (wave.abs() * (8.0 + (act.userMicVolume * 28.0))))
                      : (baseHeight + (wave.abs() * 14.0)))
                : baseHeight;
            final alpha = isActive
                ? (160 + (wave.abs() * 95)).toInt().clamp(120, 255)
                : 100;

            final dotColor = isAiActive
                ? Colors.greenAccent
                : (isUserSpeaking ? const Color(0xFFFFD54F) : Colors.white);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 4.0,
              height: dynamicHeight,
              decoration: BoxDecoration(
                color: dotColor.withAlpha(alpha),
                borderRadius: BorderRadius.circular(2.0),
              ),
            );
          }),
        );
      },
    );
  }
}
