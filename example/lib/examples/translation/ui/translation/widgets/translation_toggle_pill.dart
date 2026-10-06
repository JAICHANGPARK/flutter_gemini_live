import 'package:flutter/material.dart';

/// Tappable status pill (icon + label) used for the voice output / echo
/// prevention toggles in the language bar.
class TranslationTogglePill extends StatelessWidget {
  const TranslationTogglePill({
    super.key,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.contentColor,
    required this.label,
  });

  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color contentColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: contentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
