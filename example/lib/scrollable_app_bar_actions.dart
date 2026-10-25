import 'package:flutter/material.dart';

/// Wraps [AppBar.actions] children so they never overflow on narrow screens.
///
/// The actions are capped to a fraction of the screen width and become
/// horizontally scrollable (starting from the trailing edge) when they don't
/// fit, leaving the remaining space to the title.
class ScrollableAppBarActions extends StatelessWidget {
  const ScrollableAppBarActions({
    super.key,
    required this.children,
    this.maxWidthFraction = 0.62,
  });

  final List<Widget> children;
  final double maxWidthFraction;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveFraction = screenWidth < 480
        ? (maxWidthFraction * 0.72).clamp(0.35, 0.48)
        : maxWidthFraction;
    final maxWidth = screenWidth * effectiveFraction;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
