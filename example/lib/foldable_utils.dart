import 'dart:ui';
import 'package:flutter/material.dart';

/// Information about foldable device posture and display features (hinge/fold).
///
/// Supports:
/// - Surface Duo / dual-screen devices (physical hinge)
/// - Samsung Galaxy Z Fold / Galaxy 8 Wide (foldable screen & tabletop/flex mode)
/// - Responsive fallback for squarish wide aspect ratio foldables
class FoldableLayoutInfo {
  final bool hasHinge;
  final bool isTabletop;
  final bool isBookMode;
  final bool isDualScreen;
  final Rect? hingeBounds;
  final bool isFoldableOrWide;
  final double screenWidth;
  final double screenHeight;

  const FoldableLayoutInfo({
    required this.hasHinge,
    required this.isTabletop,
    required this.isBookMode,
    required this.isDualScreen,
    required this.hingeBounds,
    required this.isFoldableOrWide,
    required this.screenWidth,
    required this.screenHeight,
  });

  factory FoldableLayoutInfo.of(BuildContext context, {bool forceFoldable = false}) {
    final media = MediaQuery.of(context);
    final features = MediaQuery.displayFeaturesOf(context);
    final size = media.size;

    DisplayFeature? hingeFeature;
    for (final feature in features) {
      if (feature.type == DisplayFeatureType.hinge ||
          feature.type == DisplayFeatureType.fold) {
        hingeFeature = feature;
        break;
      }
    }

    final bool hasHinge = hingeFeature != null || forceFoldable;
    final Rect? bounds = hingeFeature?.bounds ??
        (forceFoldable ? Rect.fromLTWH(size.width / 2 - 8, 0, 16, size.height) : null);

    final bool isVerticalHinge = bounds != null &&
        bounds.top <= 10 &&
        bounds.bottom >= size.height - 10;

    final bool isHorizontalHinge = bounds != null &&
        bounds.left <= 10 &&
        bounds.right >= size.width - 10;

    final bool isHalfOpened = hingeFeature?.state == DisplayFeatureState.postureHalfOpened;

    final double aspectRatio = size.width / (size.height > 0 ? size.height : 1.0);
    final bool isWideFoldAspect =
        size.width >= 620 && size.width <= 1000 && aspectRatio >= 0.72 && aspectRatio <= 1.45;

    final bool isBook = isVerticalHinge || (isHalfOpened && isVerticalHinge) || forceFoldable;
    final bool isTabletop = isHorizontalHinge && (isHalfOpened || features.isNotEmpty);
    final bool isDual = hingeFeature?.type == DisplayFeatureType.hinge;

    return FoldableLayoutInfo(
      hasHinge: hasHinge,
      isTabletop: isTabletop,
      isBookMode: isBook,
      isDualScreen: isDual,
      hingeBounds: bounds,
      isFoldableOrWide: hasHinge || isWideFoldAspect,
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }
}

/// A Two-Pane responsive widget that respects foldable hinges and screen splits.
///
/// On foldable / dual-screen devices in book posture, [startPane] and [endPane]
/// are laid out on the left and right sides of the hinge.
/// When in single-pane mode, either only [startPane] or a combined scroll is rendered.
class FoldableTwoPane extends StatelessWidget {
  final Widget startPane;
  final Widget endPane;
  final Widget? hingeWidget;
  final double minWidthForTwoPane;
  final EdgeInsets padding;

  const FoldableTwoPane({
    super.key,
    required this.startPane,
    required this.endPane,
    this.hingeWidget,
    this.minWidthForTwoPane = 660,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final info = FoldableLayoutInfo.of(context);

    // If there is an active vertical hinge, split cleanly across the hinge
    if (info.hasHinge && info.hingeBounds != null && info.isBookMode) {
      final hinge = info.hingeBounds!;
      final leftWidth = hinge.left;
      final rightWidth = info.screenWidth - hinge.right;
      final hingeWidth = hinge.width.clamp(4.0, 32.0);

      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: (leftWidth - padding.left).clamp(100.0, info.screenWidth),
              child: startPane,
            ),
            SizedBox(
              width: hingeWidth,
              child: hingeWidget ??
                  Center(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
            ),
            SizedBox(
              width: (rightWidth - padding.right).clamp(100.0, info.screenWidth),
              child: endPane,
            ),
          ],
        ),
      );
    }

    // Foldable wide (unfolded Galaxy Fold style) or wide tablet screen
    if (info.isFoldableOrWide || info.screenWidth >= minWidthForTwoPane) {
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: startPane),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: double.infinity,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            Expanded(child: endPane),
          ],
        ),
      );
    }

    // Single screen fallback
    return Padding(
      padding: padding,
      child: Column(
        children: [
          startPane,
          const SizedBox(height: 16),
          endPane,
        ],
      ),
    );
  }
}
