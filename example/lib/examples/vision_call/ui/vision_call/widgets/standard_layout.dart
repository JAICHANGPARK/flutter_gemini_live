import 'package:flutter/material.dart';

import 'live_subtitle_badge.dart';

/// Standard single-column layout.
class StandardLayout extends StatelessWidget {
  const StandardLayout({
    super.key,
    required this.backgroundColor,
    required this.subtitle,
    required this.header,
    required this.viewfinder,
    required this.controlBar,
  });

  final Color backgroundColor;
  final ValueNotifier<String> subtitle;
  final Widget header;
  final Widget viewfinder;
  final Widget controlBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header (Logo + Title)
            header,

            // 2. Central Camera Viewfinder with rounded corners
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: viewfinder,
              ),
            ),

            // Live subtitle badge if any
            LiveSubtitleBadge(subtitle: subtitle),

            // 3. Bottom Control Bar (5 buttons)
            controlBar,
          ],
        ),
      ),
    );
  }
}
