import 'package:flutter/material.dart';

/// Small icon + label chip used in the stream stats row.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const StatChip(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
