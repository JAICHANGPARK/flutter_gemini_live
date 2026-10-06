import 'dart:ui' show Color;

import 'models/midi_knob_data.dart';

/// Tempo presets used by the BPM chips and the tap-to-cycle pill.
const djBpmPresets = [84, 96, 110, 120, 128, 140, 174];

/// Quick style presets (label, prompt) for the custom prompt injection.
const djPromptPresets = [
  (
    'Cyberpunk Synth',
    'Aggressive cyberpunk industrial bassline with dark analog synth arpeggios and punchy drums',
  ),
  (
    'K-Pop Dance',
    'High-energy K-Pop dance idol track with infectious bright synth brass hook, punchy sidechained dance-pop 808 bass, crisp percussion claps, and glossy modern Korean pop production',
  ),
  (
    'Lo-Fi Beats',
    'Chill lo-fi hip hop dusty vinyl crackle with warm Rhodes electric piano and boom bap drums',
  ),
  (
    'Liquid DnB',
    'Smooth 174 BPM liquid drum and bass rolling breakbeats with atmospheric vocal textures',
  ),
  (
    'French House',
    'Groovy disco filtered house pump with funky bass guitar and sidechained 909 drums',
  ),
  (
    'City Pop',
    'Sparkling 80s Japanese city pop brass stabs with slap bass and nostalgic summer vibes',
  ),
];

/// Initial text of the custom prompt field.
const djDefaultCustomPrompt =
    'Energetic futuristic dance track with heavy punchy kicks and sparkling synth arpeggios';

/// 16 default styles / instruments matching the reference design.
List<MidiKnobData> createDefaultKnobs() {
  return [
    // Row 1
    MidiKnobData(
      title: 'Bossa Nova',
      prompt:
          'Bossa Nova acoustic guitar rhythm with gentle shaker and warm bass',
      color: const Color(0xFF38BDF8), // Sky Blue
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Chillwave',
      prompt:
          'Nostalgic chillwave synthesizer chords with warm analog tape saturation',
      color: const Color(0xFF818CF8), // Indigo
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Drum and Bass',
      prompt:
          'Fast 174 BPM drum and bass rolling breakbeats and reese bassline',
      color: const Color(0xFFFB7185), // Rose
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Post Punk',
      prompt:
          'Post punk angular electric guitar riffs with driving drum machine',
      color: const Color(0xFFF472B6), // Pink
      weight: 0.0,
    ),

    // Row 2
    MidiKnobData(
      title: 'Shoegaze',
      prompt: 'Swirling ethereal shoegaze wall of fuzzy reverberant guitars',
      color: const Color(0xFFA78BFA), // Lavender
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Funk',
      prompt:
          'Funky slap bass groove with crisp rhythmic rhythm guitar and claps',
      color: const Color(0xFFFBBF24), // Amber
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Chiptune',
      prompt: '8-bit retro gaming chiptune square wave leads and arpeggios',
      color: const Color(0xFFA855F7), // Vibrant Purple (Active in reference!)
      weight: 0.65,
    ),
    MidiKnobData(
      title: 'Lush Strings',
      prompt:
          'Lush orchestral string ensemble crescendo with cinematic emotional depth',
      color: const Color(0xFF34D399), // Mint Green (Active in reference!)
      weight: 0.80,
    ),

    // Row 3
    MidiKnobData(
      title: 'Sparkling Arpeggios',
      prompt:
          'Sparkling crystalline synthesizer arpeggios floating over stereo reverb',
      color: const Color(0xFF22D3EE), // Cyan
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Staccato Rhythms',
      prompt: 'Tight staccato pizzicato rhythms and percussive melodic accents',
      color: const Color(0xFFF97316), // Orange
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Punchy Kick',
      prompt:
          'Punchy deep 4/4 electronic dance kick drum with chest-thumping low end',
      color: const Color(0xFFEF4444), // Red
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Dubstep',
      prompt: 'Heavy dubstep wobble bass growls with half-time snare beat',
      color: const Color(0xFF10B981), // Emerald
      weight: 0.0,
    ),

    // Row 4
    MidiKnobData(
      title: 'K Pop',
      prompt:
          'High-energy K-Pop dance idol track with infectious bright synth brass hook, punchy sidechained dance-pop 808 bass, crisp percussion claps, and glossy modern Korean pop production',
      color: const Color(0xFFEC4899), // Hot Pink
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Neo Soul',
      prompt:
          'Warm neo soul Fender Rhodes electric piano chords with laid-back swing beat',
      color: const Color(0xFFF59E0B), // Warm Gold
      weight: 0.0,
    ),
    MidiKnobData(
      title: 'Trip Hop',
      prompt:
          'Moody Bristol trip hop downtempo vinyl beat with dusty acoustic jazz bass',
      color: const Color(
        0xFF6366F1,
      ), // Royal Purple-Blue (Active in reference!)
      weight: 0.70,
    ),
    MidiKnobData(
      title: 'Thrash',
      prompt:
          'Aggressive fast thrash metal double-bass drumming and distorted heavy riffs',
      color: const Color(0xFFDC2626), // Crimson
      weight: 0.0,
    ),
  ];
}
