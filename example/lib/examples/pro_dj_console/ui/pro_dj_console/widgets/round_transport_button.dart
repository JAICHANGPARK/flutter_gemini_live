import 'package:flutter/material.dart';

/// Round CUE / PLAY / SYNC deck transport button.
class RoundTransportButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;

  const RoundTransportButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2432),
              border: Border.all(
                color: onPressed != null ? color : Colors.white24,
                width: 2.5,
              ),
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: color.withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon ?? Icons.album,
              color: onPressed != null ? color : Colors.white30,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? color : Colors.white30,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
