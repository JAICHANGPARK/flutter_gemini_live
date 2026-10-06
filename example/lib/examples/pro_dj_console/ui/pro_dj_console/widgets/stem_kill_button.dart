import 'package:flutter/material.dart';

/// Stem isolator kill switch.
class StemKillButton extends StatelessWidget {
  final String label;
  final bool isMuted;
  final ValueChanged<bool> onChanged;

  const StemKillButton(this.label, this.isMuted, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isMuted),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMuted ? Colors.red.shade900 : const Color(0xFF1B2230),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isMuted ? Colors.redAccent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isMuted ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
