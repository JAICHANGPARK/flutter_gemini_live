import 'package:flutter/material.dart';

import 'dj_jog_wheel.dart';
import 'round_transport_button.dart';

/// One CDJ deck (A or B): steerable prompt, jog wheel and transport.
class CdjDeck extends StatelessWidget {
  final bool isDeckA;
  final String deckAPrompt;
  final String deckBPrompt;
  final double deckAWeight;
  final double deckBWeight;
  final AnimationController jogAnim;
  final bool isPlaying;
  final bool isConnected;
  final double currentRmsL;
  final double currentRmsR;
  final int bpm;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onSync;
  final VoidCallback onEditPrompt;
  final VoidCallback onResetContext;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  const CdjDeck({
    super.key,
    required this.isDeckA,
    required this.deckAPrompt,
    required this.deckBPrompt,
    required this.deckAWeight,
    required this.deckBWeight,
    required this.jogAnim,
    required this.isPlaying,
    required this.isConnected,
    required this.currentRmsL,
    required this.currentRmsR,
    required this.bpm,
    required this.onWeightChanged,
    required this.onSync,
    required this.onEditPrompt,
    required this.onResetContext,
    required this.onPlay,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final deckColor = isDeckA
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFF9100);
    final deckTitle = isDeckA ? 'DECK 1 (A)' : 'DECK 2 (B)';
    final promptText = isDeckA ? deckAPrompt : deckBPrompt;
    final promptWeight = isDeckA ? deckAWeight : deckBWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262E3E), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck Header & Vinyl Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: deckColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: deckColor.withAlpha(180),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    deckTitle,
                    style: TextStyle(
                      color: deckColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'VINYL MODE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Steerable Prompt Text Editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1D222E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: deckColor.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEERABLE PROMPT',
                      style: TextStyle(
                        color: deckColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'WEIGHT: ${promptWeight.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  promptText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: deckColor,
                        ),
                        child: Slider(
                          value: promptWeight,
                          min: 0.1,
                          max: 1.0,
                          onChanged: (val) {
                            onWeightChanged(val);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white70,
                      ),
                      onPressed: () => onEditPrompt(),
                      tooltip: 'Edit Prompt',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CDJ Style Jog Wheel
          Center(
            child: DjJogWheel(
              anim: jogAnim,
              isPlaying: isPlaying,
              deckColor: deckColor,
              rms: isDeckA ? currentRmsL : currentRmsR,
              bpm: bpm,
              onTap: () {
                if (isConnected) {
                  onResetContext();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Deck Transport (CUE / PLAY)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoundTransportButton(
                label: 'CUE',
                color: Colors.amber,
                onPressed: isConnected ? onPause : null,
              ),
              RoundTransportButton(
                label: 'PLAY',
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.greenAccent,
                onPressed: isConnected ? (isPlaying ? onPause : onPlay) : null,
              ),
              RoundTransportButton(
                label: 'SYNC',
                color: Colors.blueAccent,
                onPressed: () {
                  onSync();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
