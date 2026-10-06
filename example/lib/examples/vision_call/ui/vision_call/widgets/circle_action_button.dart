import 'package:flutter/material.dart';

/// Round 52px action button used in the bottom control bar.
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.tooltip,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}
