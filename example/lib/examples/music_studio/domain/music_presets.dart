import 'package:gemini_live/gemini_live.dart';

import 'models/music_preset.dart';

/// Initial prompts from the official Google Prompt DJ guide.
const List<MapEntry<String, double>> kInitialMusicPrompts = [
  MapEntry(
    'Minimal techno with deep bass, sparse percussion, and atmospheric synths',
    1.0,
  ),
  MapEntry('Shimmering hi-hats and acid 303 bass', 0.8),
];

/// Quick presets matching the official Google Lyria guide.
const List<MusicPreset> kMusicPresets = [
  MusicPreset(
    label: 'Minimal Techno',
    prompts: [
      MapEntry(
        'Minimal techno with deep bass, sparse percussion, and atmospheric synths',
        1.0,
      ),
      MapEntry('Shimmering hi-hats and acid 303 bass', 0.8),
    ],
    bpm: 128,
    mode: MusicGenerationMode.QUALITY,
  ),
  MusicPreset(
    label: 'Lo-Fi Study Beat',
    prompts: [
      MapEntry('Lo-fi hip hop beat with dusty vinyl crackle', 1.0),
      MapEntry('Mellow Rhodes piano chords & warm upright bassline', 0.8),
    ],
    bpm: 82,
    scale: Scale.C_MAJOR_A_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  MusicPreset(
    label: 'Cyberpunk 110',
    prompts: [
      MapEntry('Dark, cinematic cyberpunk synthwave in D minor', 1.0),
      MapEntry('Heavy distorted 303 bass & analog synths', 0.8),
    ],
    bpm: 110,
    scale: Scale.D_MAJOR_B_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  MusicPreset(
    label: 'Ambient Drone',
    prompts: [
      MapEntry('Ambient synth pads with ethereal strings', 1.0),
      MapEntry('Subtle reverberant piano', 0.7),
    ],
    bpm: 72,
    mode: MusicGenerationMode.DIVERSITY,
  ),
  MusicPreset(
    label: 'Afrobeat Groove',
    prompts: [
      MapEntry('Afrobeat rhythm & brass section', 1.0),
      MapEntry('Funky bassline and percussion groove', 0.7),
    ],
    bpm: 118,
    mode: MusicGenerationMode.QUALITY,
  ),
];
