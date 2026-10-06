import 'package:flutter/material.dart';

/// YouTube URL / video ID input with a load button.
class UrlBar extends StatelessWidget {
  const UrlBar({super.key, required this.controller, required this.onLoad});

  final TextEditingController controller;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.ondemand_video, color: Colors.redAccent),
                hintText: 'YouTube 링크 또는 Video ID 입력 (e.g. XEzRZ33sJCE)',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => onLoad(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.cyanAccent.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onLoad,
          child: const Text(
            '로드',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
