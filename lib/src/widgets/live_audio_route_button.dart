import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Audio output hardware route for a live voice call.
enum GeminiLiveAudioRoute {
  /// Built-in loudspeaker / speakerphone.
  speaker,

  /// Built-in receiver / phone earpiece.
  earpiece,

  /// Wired headphones or USB-C / Lightning headset.
  headphones,

  /// Bluetooth headset, AirPods, or car audio.
  bluetooth,
}

/// Extension providing human-readable labels and default icons for [GeminiLiveAudioRoute].
extension GeminiLiveAudioRouteExtension on GeminiLiveAudioRoute {
  /// Standard human-readable display name for this audio route.
  String get label {
    switch (this) {
      case GeminiLiveAudioRoute.speaker:
        return 'Speaker';
      case GeminiLiveAudioRoute.earpiece:
        return 'Phone Earpiece';
      case GeminiLiveAudioRoute.headphones:
        return 'Headphones';
      case GeminiLiveAudioRoute.bluetooth:
        return 'Bluetooth Audio';
    }
  }

  /// Standard Material icon representing this audio route.
  IconData get iconData {
    switch (this) {
      case GeminiLiveAudioRoute.speaker:
        return Icons.volume_up_rounded;
      case GeminiLiveAudioRoute.earpiece:
        return Icons.phone_in_talk_rounded;
      case GeminiLiveAudioRoute.headphones:
        return Icons.headphones_rounded;
      case GeminiLiveAudioRoute.bluetooth:
        return Icons.bluetooth_audio_rounded;
    }
  }
}

/// Builder signature for providing a custom icon widget for a given [GeminiLiveAudioRoute].
typedef GeminiLiveAudioRouteIconBuilder =
    Widget Function(
      BuildContext context,
      GeminiLiveAudioRoute route,
      Color foregroundColor,
    );

/// A native call-styled audio output route toggle/selector button.
///
/// Designed to slot directly into [GeminiLiveControlBar.trailing] or any voice call toolbar.
/// - When [showRoutePickerOnTap] is `false` (default when only 2 routes exist),
///   tapping cycles cleanly between [availableRoutes] (e.g., Speaker <-> Earpiece).
/// - When [showRoutePickerOnTap] is `true`, tapping opens a restrained native modal sheet
///   allowing the user to choose among [availableRoutes].
class GeminiLiveAudioRouteButton extends StatelessWidget {
  /// Currently selected audio output route.
  final GeminiLiveAudioRoute currentRoute;

  /// Callback invoked when the user selects or toggles to a new route.
  final ValueChanged<GeminiLiveAudioRoute>? onRouteChanged;

  /// List of available hardware routes. Defaults to `[speaker, earpiece]`.
  final List<GeminiLiveAudioRoute> availableRoutes;

  /// Whether tapping opens a bottom sheet picker instead of cycling directly.
  /// If null, automatically opens the sheet when `availableRoutes.length > 2`.
  final bool? showRoutePickerOnTap;

  /// Diameter of the circular button. Defaults to `44.0` to match `GeminiLiveControlBar`.
  final double size;

  /// Size of the inner route icon. Defaults to `21.0`.
  final double iconSize;

  /// Optional custom icon builder overriding the default route icons.
  final GeminiLiveAudioRouteIconBuilder? iconBuilder;

  /// Optional custom background color when highlighted (e.g. speakerphone active).
  final Color? activeBackgroundColor;

  /// Optional custom background color when in default/earpiece mode.
  final Color? inactiveBackgroundColor;

  /// Optional custom foreground color when highlighted.
  final Color? activeForegroundColor;

  /// Optional custom foreground color when in default/earpiece mode.
  final Color? inactiveForegroundColor;

  /// Whether to trigger subtle haptic feedback on tap. Defaults to `true`.
  final bool enableHaptics;

  /// Optional tooltip text.
  final String? tooltip;

  /// Title shown at the top of the modal route picker sheet.
  final String pickerTitle;

  /// Creates a native call audio output route button.
  const GeminiLiveAudioRouteButton({
    super.key,
    required this.currentRoute,
    this.onRouteChanged,
    this.availableRoutes = const [
      GeminiLiveAudioRoute.speaker,
      GeminiLiveAudioRoute.earpiece,
    ],
    this.showRoutePickerOnTap,
    this.size = 44.0,
    this.iconSize = 21.0,
    this.iconBuilder,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.activeForegroundColor,
    this.inactiveForegroundColor,
    this.enableHaptics = true,
    this.tooltip,
    this.pickerTitle = 'Audio Output',
  }) : assert(
         availableRoutes.length > 0,
         'availableRoutes must not be empty.',
       );

  bool get _isHighlighted => currentRoute == GeminiLiveAudioRoute.speaker;

  void _handleTap(BuildContext context) {
    if (onRouteChanged == null) return;
    if (enableHaptics) {
      HapticFeedback.lightImpact();
    }

    final useSheet = showRoutePickerOnTap ?? (availableRoutes.length > 2);
    if (useSheet) {
      _showRoutePicker(context);
      return;
    }

    final currentIndex = availableRoutes.indexOf(currentRoute);
    final nextIndex = (currentIndex + 1) % availableRoutes.length;
    onRouteChanged!(availableRoutes[nextIndex]);
  }

  Future<void> _showRoutePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<GeminiLiveAudioRoute>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF18181B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF09090B);
        final subColor = isDark
            ? const Color(0xFFA1A1AA)
            : const Color(0xFF71717A);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Material(
              color: sheetBg,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    pickerTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                for (final route in availableRoutes)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading:
                        iconBuilder?.call(sheetContext, route, textColor) ??
                        Icon(route.iconData, color: textColor, size: 20),
                    title: Text(
                      route.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: route == currentRoute
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: route == currentRoute
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: textColor,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(route),
                  ),
              ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && selected != currentRoute) {
      onRouteChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) { // coverage:ignore-line
      brightness = CupertinoTheme.maybeBrightnessOf(context); // coverage:ignore-line
    }
    final isDark = brightness == Brightness.dark;

    final effectiveBg = _isHighlighted
        ? (activeBackgroundColor ??
              (isDark ? Colors.white : const Color(0xFF18181B)))
        : (inactiveBackgroundColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06)));

    final effectiveFg = _isHighlighted
        ? (activeForegroundColor ??
              (isDark ? const Color(0xFF09090B) : Colors.white))
        : (inactiveForegroundColor ??
              (isDark ? Colors.white : const Color(0xFF18181B)));

    return Tooltip(
      message: tooltip ?? 'Audio Output: ${currentRoute.label}',
      child: GestureDetector(
        onTap: onRouteChanged != null ? () => _handleTap(context) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: effectiveBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                iconBuilder?.call(context, currentRoute, effectiveFg) ??
                Icon(
                  currentRoute.iconData,
                  color: effectiveFg,
                  size: iconSize,
                ),
          ),
        ),
      ),
    );
  }
}
