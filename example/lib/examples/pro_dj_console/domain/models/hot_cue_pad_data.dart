import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

/// One of the 8 performance pad presets (prompts, tempo, scale, mode).
class HotCuePadData {
  final String label;
  final Color color;
  final String promptA;
  final String promptB;
  final int bpm;
  final Scale? scale;
  final MusicGenerationMode mode;
  final bool isHardDrop;

  const HotCuePadData({
    required this.label,
    required this.color,
    required this.promptA,
    required this.promptB,
    required this.bpm,
    this.scale,
    required this.mode,
    this.isHardDrop = false,
  });
}
