import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Material 3 Window Size Classes for responsive and adaptive layouts.
enum GeminiLiveWindowSizeClass {
  /// Compact width (`< 600` dp): phones in portrait, foldable cover displays.
  compact,

  /// Medium width (`600 <= width < 840` dp): unfolded foldables, tablets in portrait.
  medium,

  /// Expanded width (`>= 840` dp): tablets in landscape, desktop, web, ultra-wide displays.
  expanded,
}

/// Physical posture of a foldable or dual-screen device derived from [ui.DisplayFeature].
enum GeminiLiveFoldPosture {
  /// Standard flat screen with no separating hinge or fold.
  flat,

  /// Vertical fold or hinge separating the screen into left and right panes (Book posture).
  book,

  /// Horizontal fold or hinge separating the screen into top display and bottom controls (Tabletop / Flex posture).
  tabletop,
}

/// Layout arrangement mode for adaptive Gemini Live widgets.
enum GeminiLiveAdaptiveLayoutMode {
  /// Automatically selects [singlePane], [dualPane], or [tabletop] based on
  /// foldable [ui.DisplayFeature] posture and screen width breakpoint.
  auto,

  /// Single-column vertical stacked layout.
  singlePane,

  /// Side-by-side two-pane horizontal layout (Book mode / tablet / desktop).
  dualPane,

  /// Top-and-bottom split layout aligned to a horizontal hinge (Flex / Tabletop mode).
  tabletop,
}

/// Immutable snapshot of the current viewport, window size class, and foldable hinge state.
///
/// Computed via [GeminiLiveViewportInfo.of] or delivered by [GeminiLiveResponsiveBuilder].
class GeminiLiveViewportInfo {
  /// Effective available size of the viewport or parent layout constraints.
  final Size size;

  /// Material 3 window size class ([compact], [medium], or [expanded]).
  final GeminiLiveWindowSizeClass windowSizeClass;

  /// Current orientation of the viewport.
  final Orientation orientation;

  /// Detected foldable posture ([flat], [book], or [tabletop]).
  final GeminiLiveFoldPosture foldPosture;

  /// Primary separating hinge or fold [ui.DisplayFeature], if present.
  final ui.DisplayFeature? displayFeature;

  /// Bounding rectangle of the physical hinge or fold in global/screen coordinates, if any.
  final Rect? hingeBounds;

  /// Creates a [GeminiLiveViewportInfo] snapshot.
  const GeminiLiveViewportInfo({
    required this.size,
    required this.windowSizeClass,
    required this.orientation,
    this.foldPosture = GeminiLiveFoldPosture.flat,
    this.displayFeature,
    this.hingeBounds,
  });

  /// Computes [GeminiLiveViewportInfo] from the current [BuildContext] and optional [BoxConstraints].
  factory GeminiLiveViewportInfo.of(
    BuildContext context, {
    BoxConstraints? constraints,
  }) {
    final mediaSize = MediaQuery.sizeOf(context);
    final effectiveWidth =
        (constraints != null &&
            constraints.hasBoundedWidth &&
            constraints.maxWidth.isFinite)
        ? math.min(constraints.maxWidth, mediaSize.width)
        : mediaSize.width;
    final effectiveHeight =
        (constraints != null &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite)
        ? math.min(constraints.maxHeight, mediaSize.height)
        : mediaSize.height;
    final size = Size(effectiveWidth, effectiveHeight);

    final GeminiLiveWindowSizeClass sizeClass;
    if (effectiveWidth < 600.0) {
      sizeClass = GeminiLiveWindowSizeClass.compact;
    } else if (effectiveWidth < 840.0) {
      sizeClass = GeminiLiveWindowSizeClass.medium;
    } else {
      sizeClass = GeminiLiveWindowSizeClass.expanded;
    }

    final orientation = effectiveWidth > effectiveHeight
        ? Orientation.landscape
        : Orientation.portrait;

    final features = MediaQuery.displayFeaturesOf(context);
    ui.DisplayFeature? primaryFeature;
    var posture = GeminiLiveFoldPosture.flat;

    for (final feature in features) {
      final isHingeOrFold =
          feature.type == ui.DisplayFeatureType.hinge ||
          feature.type == ui.DisplayFeatureType.fold;
      if (!isHingeOrFold) continue;

      final bounds = feature.bounds;
      final isHalfOpened =
          feature.state == ui.DisplayFeatureState.postureHalfOpened;
      final hasPhysicalThickness = bounds.width > 0.0 || bounds.height > 0.0;
      final spansVertically = bounds.height >= mediaSize.height * 0.5;
      final spansHorizontally = bounds.width >= mediaSize.width * 0.5;

      if (spansVertically &&
          bounds.height >= bounds.width &&
          (isHalfOpened || hasPhysicalThickness)) {
        primaryFeature = feature;
        posture = GeminiLiveFoldPosture.book;
        break;
      } else if (spansHorizontally &&
          bounds.width > bounds.height &&
          (isHalfOpened || bounds.height > 0.0)) {
        primaryFeature = feature;
        posture = GeminiLiveFoldPosture.tabletop;
        break;
      }
    }

    return GeminiLiveViewportInfo(
      size: size,
      windowSizeClass: sizeClass,
      orientation: orientation,
      foldPosture: posture,
      displayFeature: primaryFeature,
      hingeBounds: primaryFeature?.bounds,
    );
  }

  /// Whether the viewport is in the compact width class (`< 600` dp).
  bool get isCompact => windowSizeClass == GeminiLiveWindowSizeClass.compact;

  /// Whether the viewport is in the medium width class (`600 <= width < 840` dp).
  bool get isMedium => windowSizeClass == GeminiLiveWindowSizeClass.medium;

  /// Whether the viewport is in the expanded width class (`>= 840` dp).
  bool get isExpanded => windowSizeClass == GeminiLiveWindowSizeClass.expanded;

  /// Whether the viewport is medium or expanded (`>= 600` dp) or in foldable book posture.
  bool get isWide => !isCompact || isBookPosture;

  /// Whether the viewport is an ultra-narrow screen (`< 340` dp, such as a foldable cover screen).
  bool get isUltraNarrow => size.width < 340.0;

  /// Whether the viewport has limited vertical height (`< 480` dp, such as landscape phone or tabletop pane).
  bool get isShortHeight => size.height < 480.0;

  /// Whether the device has an active separating foldable hinge or half-opened fold.
  bool get hasSeparatingHinge => foldPosture != GeminiLiveFoldPosture.flat;

  /// Whether the device is in a left/right foldable Book posture.
  bool get isBookPosture => foldPosture == GeminiLiveFoldPosture.book;

  /// Whether the device is in a top/bottom foldable Tabletop (Flex) posture.
  bool get isTabletopPosture => foldPosture == GeminiLiveFoldPosture.tabletop;

  /// Recommended maximum width for centered chat or content columns on wide screens.
  double? get recommendedMaxContentWidth {
    if (isExpanded) return 860.0;
    if (isMedium) return 700.0;
    return null;
  }

  /// Recommended maximum width for modal bottom sheets on tablets, desktops, and foldables.
  double get recommendedModalMaxWidth => isCompact ? double.infinity : 560.0;

  /// Adaptive horizontal padding that tightens on ultra-narrow cover displays and breathes on tablets.
  double get adaptiveHorizontalPadding {
    if (isUltraNarrow) return 10.0;
    if (isExpanded) return 24.0;
    if (isMedium) return 20.0;
    return 14.0;
  }

  /// Resolves [GeminiLiveAdaptiveLayoutMode.auto] into a concrete layout mode
  /// ([GeminiLiveAdaptiveLayoutMode.singlePane], [GeminiLiveAdaptiveLayoutMode.dualPane],
  /// or [GeminiLiveAdaptiveLayoutMode.tabletop]).
  GeminiLiveAdaptiveLayoutMode resolveLayoutMode(
    GeminiLiveAdaptiveLayoutMode requested, {
    double breakpoint = 600.0,
  }) {
    if (requested != GeminiLiveAdaptiveLayoutMode.auto) {
      return requested;
    }
    if (isBookPosture) {
      return GeminiLiveAdaptiveLayoutMode.dualPane;
    }
    if (isTabletopPosture) {
      return GeminiLiveAdaptiveLayoutMode.tabletop;
    }
    if (size.width >= breakpoint) {
      return GeminiLiveAdaptiveLayoutMode.dualPane;
    }
    return GeminiLiveAdaptiveLayoutMode.singlePane;
  }
}

/// Builder widget that provides [GeminiLiveViewportInfo] combining parent
/// [LayoutBuilder] constraints and device [MediaQuery] foldable display features.
class GeminiLiveResponsiveBuilder extends StatelessWidget {
  /// Builder callback receiving the current [BuildContext] and [GeminiLiveViewportInfo].
  final Widget Function(BuildContext context, GeminiLiveViewportInfo viewport)
  builder;

  /// Creates a responsive builder for Gemini Live UI components.
  const GeminiLiveResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = GeminiLiveViewportInfo.of(
          context,
          constraints: constraints,
        );
        return builder(context, viewport);
      },
    );
  }
}

/// An adaptive, foldable-aware split-view widget that automatically transitions
/// between a single vertical stack, a side-by-side dual-pane layout (Book mode /
/// tablet / desktop), and a horizontal hinge-aligned top/bottom layout (Tabletop / Flex mode).
///
/// When [respectFoldableHinge] is `true` and a physical [ui.DisplayFeature] hinge
/// is present, [GeminiLiveAdaptiveSplitView] automatically sizes panes around the
/// hinge bounds so no interactive controls or text are obscured by the crease/hinge.
class GeminiLiveAdaptiveSplitView extends StatelessWidget {
  /// Primary pane widget (top pane in vertical/tabletop mode, left pane in dual-pane mode).
  final Widget primaryPane;

  /// Secondary pane widget (bottom pane in vertical/tabletop mode, right pane in dual-pane mode).
  final Widget secondaryPane;

  /// Optional middle widget placed between [primaryPane] and [secondaryPane]
  /// (e.g., a language swap pill or divider).
  final Widget? centerWidget;

  /// Optional bottom footer or transport/microphone control widget.
  final Widget? bottomControls;

  /// Layout mode ([GeminiLiveAdaptiveLayoutMode.auto] by default).
  final GeminiLiveAdaptiveLayoutMode mode;

  /// Width threshold (in logical pixels) at which [GeminiLiveAdaptiveLayoutMode.auto]
  /// switches from [GeminiLiveAdaptiveLayoutMode.singlePane] to [GeminiLiveAdaptiveLayoutMode.dualPane].
  ///
  /// Defaults to `600.0`.
  final double breakpoint;

  /// Whether to align panes around physical foldable hinges ([ui.DisplayFeature]).
  ///
  /// Defaults to `true`.
  final bool respectFoldableHinge;

  /// Flex factor for [primaryPane] when no physical hinge dictates exact pixel widths.
  ///
  /// Defaults to `1`.
  final int primaryFlex;

  /// Flex factor for [secondaryPane] when no physical hinge dictates exact pixel widths.
  ///
  /// Defaults to `1`.
  final int secondaryFlex;

  /// Spacing between panes. Defaults to `12.0`.
  final double spacing;

  /// Optional outer padding around the split view.
  final EdgeInsetsGeometry? padding;

  /// Whether to swap the visual order of [primaryPane] and [secondaryPane] in [dualPane] mode.
  final bool reversePanesInDualMode;

  /// Creates a foldable- and tablet-aware split view.
  const GeminiLiveAdaptiveSplitView({
    super.key,
    required this.primaryPane,
    required this.secondaryPane,
    this.centerWidget,
    this.bottomControls,
    this.mode = GeminiLiveAdaptiveLayoutMode.auto,
    this.breakpoint = 600.0,
    this.respectFoldableHinge = true,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.spacing = 12.0,
    this.padding,
    this.reversePanesInDualMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GeminiLiveResponsiveBuilder(
      builder: (context, viewport) {
        final effectiveMode = viewport.resolveLayoutMode(
          mode,
          breakpoint: breakpoint,
        );

        Widget content;
        switch (effectiveMode) {
          case GeminiLiveAdaptiveLayoutMode.dualPane:
            content = _buildDualPane(context, viewport);
            break;
          case GeminiLiveAdaptiveLayoutMode.tabletop:
            content = _buildTabletopPane(context, viewport);
            break;
          case GeminiLiveAdaptiveLayoutMode.singlePane:
          case GeminiLiveAdaptiveLayoutMode.auto:
            content = _buildSinglePane(context, viewport);
            break;
        }

        if (padding != null) {
          return Padding(padding: padding!, child: content);
        }
        return content;
      },
    );
  }

  Widget _buildSinglePane(
    BuildContext context,
    GeminiLiveViewportInfo viewport,
  ) {
    final effectiveSpacing = viewport.isShortHeight
        ? math.min(spacing, 6.0)
        : spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: primaryFlex, child: primaryPane),
        if (centerWidget != null) ...[
          SizedBox(height: effectiveSpacing),
          Center(child: centerWidget!),
          SizedBox(height: effectiveSpacing),
        ] else
          SizedBox(height: effectiveSpacing),
        Expanded(flex: secondaryFlex, child: secondaryPane),
        if (bottomControls != null) ...[
          SizedBox(height: effectiveSpacing),
          Center(child: bottomControls!),
        ],
      ],
    );
  }

  Widget _buildTabletopPane(
    BuildContext context,
    GeminiLiveViewportInfo viewport,
  ) {
    final hinge = respectFoldableHinge ? viewport.hingeBounds : null;
    final totalHeight = viewport.size.height;

    if (hinge != null &&
        totalHeight.isFinite &&
        hinge.top > 40.0 &&
        hinge.bottom < totalHeight - 40.0) {
      final topHeight = math.max(0.0, hinge.top);
      final hingeGap = math.max(hinge.height, spacing);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topHeight, child: primaryPane),
          SizedBox(
            height: hingeGap,
            child: centerWidget != null ? Center(child: centerWidget!) : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hingeGap < 28.0 && centerWidget != null) ...[
                  Center(child: centerWidget!),
                  const SizedBox(height: 6.0),
                ],
                Expanded(child: secondaryPane),
                if (bottomControls != null) ...[
                  const SizedBox(height: 8.0),
                  Center(child: bottomControls!),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return _buildSinglePane(context, viewport);
  }

  Widget _buildDualPane(BuildContext context, GeminiLiveViewportInfo viewport) {
    final first = reversePanesInDualMode ? secondaryPane : primaryPane;
    final second = reversePanesInDualMode ? primaryPane : secondaryPane;
    final firstFlex = reversePanesInDualMode ? secondaryFlex : primaryFlex;
    final secondFlex = reversePanesInDualMode ? primaryFlex : secondaryFlex;

    final hinge = respectFoldableHinge && viewport.isBookPosture
        ? viewport.hingeBounds
        : null;
    final totalWidth = viewport.size.width;

    Widget row;
    if (hinge != null &&
        totalWidth.isFinite &&
        hinge.left > 60.0 &&
        hinge.right < totalWidth - 60.0) {
      final leftWidth = math.max(0.0, hinge.left);
      final hingeGap = math.max(hinge.width, spacing);
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: leftWidth, child: first),
          if (centerWidget != null) ...[
            SizedBox(width: hingeGap / 2),
            Center(child: centerWidget!),
            SizedBox(width: hingeGap / 2),
          ] else
            SizedBox(width: hingeGap),
          Expanded(child: second),
        ],
      );
    } else {
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: firstFlex, child: first),
          if (centerWidget != null) ...[
            SizedBox(width: spacing),
            Center(child: centerWidget!),
            SizedBox(width: spacing),
          ] else
            SizedBox(width: spacing),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    }

    if (bottomControls == null) {
      return row;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: row),
        SizedBox(height: spacing),
        Center(child: bottomControls!),
      ],
    );
  }
}

/// An adaptive container for modal bottom sheets and dialogs that automatically
/// constrains width on tablets, desktops, and unfolded foldables while adapting
/// padding for ultra-narrow cover displays and keyboard insets.
class GeminiLiveAdaptiveSheetContainer extends StatelessWidget {
  /// Child content of the modal sheet.
  final Widget child;

  /// Background color of the sheet surface.
  final Color? backgroundColor;

  /// Maximum width on medium/expanded screens. Defaults to `560.0`.
  final double maxWidth;

  /// Inner padding of the sheet. If null, adapts automatically to viewport width.
  final EdgeInsetsGeometry? padding;

  /// Top border radius of the sheet. Defaults to `24.0`.
  final double topRadius;

  /// Optional border around the sheet.
  final BoxBorder? border;

  /// Whether to include bottom keyboard viewInsets padding automatically. Defaults to `false`.
  final bool includeKeyboardInsets;

  /// Creates a responsive modal bottom sheet container.
  const GeminiLiveAdaptiveSheetContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.maxWidth = 560.0,
    this.padding,
    this.topRadius = 24.0,
    this.border,
    this.includeKeyboardInsets = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewport = GeminiLiveViewportInfo.of(context);
    final bottomInset = includeKeyboardInsets
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final horizontalPad = viewport.isUltraNarrow ? 14.0 : 20.0;
    final effectivePadding =
        padding ??
        EdgeInsets.fromLTRB(
          horizontalPad,
          14.0,
          horizontalPad,
          28.0 + bottomInset,
        );

    final sheetBox = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: viewport.isCompact ? double.infinity : maxWidth,
        maxHeight: viewport.size.height * 0.9,
      ),
      child: Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          border: border,
        ),
        child: child,
      ),
    );

    if (viewport.isCompact) {
      return sheetBox;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: sheetBox,
    );
  }
}
