import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import 'models/hot_cue_pad_data.dart';

/// Hot Cue Pad Presets
final List<HotCuePadData> defaultHotCuePads = [
  HotCuePadData(
    label: '909 TECHNO',
    color: Colors.cyanAccent,
    promptA:
        'Peak-time Berlin techno with pounding 909 kick and dark warehouse ambiance',
    promptB:
        'Hypnotic modular synth arpeggios and industrial metallic percussion',
    bpm: 130,
    scale: Scale.C_MAJOR_A_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  HotCuePadData(
    label: 'ACID 303',
    color: const Color(0xFF76FF03),
    promptA: 'Resonant TB-303 acid bassline with screaming filter sweeps',
    promptB: 'Crisp electro breakbeats and analogue clap sequences',
    bpm: 126,
    scale: Scale.D_MAJOR_B_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  HotCuePadData(
    label: 'LO-FI STUDY',
    color: Colors.amberAccent,
    promptA: 'Mellow lo-fi hip hop beat with dusty vinyl crackle',
    promptB:
        'Warm Fender Rhodes electric piano chords and acoustic upright bass',
    bpm: 84,
    scale: Scale.C_MAJOR_A_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  HotCuePadData(
    label: 'AFROBEAT',
    color: Colors.orangeAccent,
    promptA:
        'Uplifting Afrobeat groove with brass horn section and talking drums',
    promptB: 'Funky rhythmic rhythm guitar and polyrhythmic percussion',
    bpm: 116,
    scale: Scale.G_MAJOR_E_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  HotCuePadData(
    label: 'CYBERPUNK',
    color: Colors.purpleAccent,
    promptA: 'Dark cinematic cyberpunk synthwave with heavy distorted bass',
    promptB: 'Retro neon 80s lead synths and gated snare drums',
    bpm: 110,
    scale: Scale.D_MAJOR_B_MINOR,
    mode: MusicGenerationMode.QUALITY,
  ),
  HotCuePadData(
    label: 'AMBIENT DRONE',
    color: Colors.lightBlueAccent,
    promptA: 'Deep ethereal ambient synth drone with infinite reverberation',
    promptB: 'Subtle crystal piano drops and atmospheric string textures',
    bpm: 70,
    scale: Scale.F_MAJOR_D_MINOR,
    mode: MusicGenerationMode.DIVERSITY,
  ),
  HotCuePadData(
    label: 'VOCAL CHOPS',
    color: Colors.pinkAccent,
    promptA: 'Euphoric melodic progressive house with vocal chops and piano',
    promptB: 'Soulful human voice hums and choral vocalization layers',
    bpm: 124,
    scale: Scale.A_MAJOR_G_FLAT_MINOR,
    mode: MusicGenerationMode.VOCALIZATION,
  ),
  HotCuePadData(
    label: 'DROP & RESET',
    color: Colors.redAccent,
    promptA: 'Massive festival EDM drop with driving synth leads and heavy sub',
    promptB: 'Punchy snare roll build-up into explosive bass drop',
    bpm: 128,
    scale: Scale.D_MAJOR_B_MINOR,
    mode: MusicGenerationMode.QUALITY,
    isHardDrop: true,
  ),
];
