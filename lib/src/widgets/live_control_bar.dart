import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An all-in-one floating call control bar for Gemini Live voice and multimodal sessions.
///
/// Provides essential call interaction buttons:
/// - Microphone Toggle (Mute / Unmute)
/// - Camera Video Toggle (On / Off)
/// - Camera Direction Flip (Front / Rear)
/// - End Call / Disconnect (Red hang up button)
///
/// Designed with glassmorphism surface styling compatible with both Material 3
/// and Cupertino environments.
class GeminiLiveControlBar extends StatelessWidget {
  /// Whether the microphone is currently active / unmuted.
  final bool isMicActive;

  /// Callback to toggle microphone active state.
  final VoidCallback onToggleMic;

  /// Whether video/camera is currently enabled.
  final bool isVideoActive;

  /// Callback to toggle video active state.
  final VoidCallback onToggleVideo;

  /// Callback to switch/flip camera between front and rear.
  final VoidCallback? onFlipCamera;

  /// Callback when user taps the disconnect / end call button.
  final VoidCallback? onEndCall;

  /// Whether to show the flip camera button. Defaults to `true` if [onFlipCamera] is provided.
  final bool showFlipCamera;

  /// Optional custom button to add as an extra action (e.g., chat sheet or settings).
  final Widget? trailing;

  /// Background color of the control bar pill.
  final Color? backgroundColor;

  /// Height of the control bar. Defaults to 64.0.
  final double height;

  /// Spacing between buttons. Defaults to 12.0.
  final double spacing;

  /// Creates a floating call control bar for Gemini Live sessions.
  const GeminiLiveControlBar({
    super.key,
    required this.isMicActive,
    required this.onToggleMic,
    this.isVideoActive = true,
    required this.onToggleVideo,
    this.onFlipCamera,
    this.onEndCall,
    this.showFlipCamera = true,
    this.trailing,
    this.backgroundColor,
    this.height = 64.0,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }

    final isDark = brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark
            ? const Color(0xCC18181B)
            : const Color(0xE6FFFFFF));

    final inactiveBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    final activeBtnBg = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF2563EB);

    final inactiveBtnFg = isDark ? Colors.white70 : Colors.black87;
    const activeBtnFg = Colors.white;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 20.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Microphone Toggle
          _ControlButton(
            icon: isMicActive ? Icons.mic : Icons.mic_off,
            tooltip: isMicActive ? 'Mute Microphone' : 'Unmute Microphone',
            backgroundColor: isMicActive ? activeBtnBg : inactiveBtnBg,
            foregroundColor: isMicActive ? activeBtnFg : inactiveBtnFg,
            onPressed: onToggleMic,
          ),
          SizedBox(width: spacing),

          // Video Toggle
          _ControlButton(
            icon: isVideoActive ? Icons.videocam : Icons.videocam_off,
            tooltip: isVideoActive ? 'Turn Video Off' : 'Turn Video On',
            backgroundColor: isVideoActive ? activeBtnBg : inactiveBtnBg,
            foregroundColor: isVideoActive ? activeBtnFg : inactiveBtnFg,
            onPressed: onToggleVideo,
          ),

          // Flip Camera (Optional)
          if (showFlipCamera && onFlipCamera != null) ...[
            SizedBox(width: spacing),
            _ControlButton(
              icon: Icons.flip_camera_ios_rounded,
              tooltip: 'Switch Camera',
              backgroundColor: inactiveBtnBg,
              foregroundColor: inactiveBtnFg,
              onPressed: onFlipCamera!,
            ),
          ],

          // Trailing widget (e.g. Chat or Settings)
          if (trailing != null) ...[
            SizedBox(width: spacing),
            trailing!,
          ],

          // End Call Button
          if (onEndCall != null) ...[
            SizedBox(width: spacing),
            _ControlButton(
              icon: Icons.call_end_rounded,
              tooltip: 'End Call',
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              onPressed: onEndCall!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: foregroundColor,
                size: 20.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
