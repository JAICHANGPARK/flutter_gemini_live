import 'package:flutter/material.dart';

import '../google_genai.dart';
import '../utils/live_session_controller.dart';
import 'live_adaptive_layout.dart';
import 'live_mic_button.dart';
import 'live_status_badge.dart';
import 'live_waveform.dart';

/// Builder signature for customizing a language transcript pane in [GeminiLiveTranslateSplitView].
typedef GeminiLiveTranslatePaneBuilder =
    Widget Function(
      BuildContext context,
      String languageCode,
      String languageLabel,
      String? latestText,
      List<LiveTranscriptItem> items,
      bool isActive,
    );

/// Builder signature for customizing the middle language selector bar in [GeminiLiveTranslateSplitView].
typedef GeminiLiveTranslateLanguageBarBuilder =
    Widget Function(
      BuildContext context,
      String sourceLanguageCode,
      String targetLanguageCode,
      VoidCallback onSwap,
    );

/// A clean, native interpreter-styled dual-pane live translation view designed for
/// [LiveModels.gemini35LiveTranslatePreview] (`gemini-3.5-live-translate-preview`) and [TranslationConfig].
///
/// Inspired by hardware interpreter devices and Apple Translate's Conversation view:
/// - **Top Pane**: Displays translated target-language output (optionally rotated 180°
///   when [faceToFaceMode] is enabled for across-the-table conversations).
/// - **Middle Bar**: Clean language pills with one-tap language direction swap.
/// - **Bottom Pane**: Displays source-language transcripts and microphone controls.
class GeminiLiveTranslateSplitView extends StatefulWidget {
  /// Optional Google Gemini API key. Required unless [controller] is provided.
  final String? apiKey;

  /// Optional external [GeminiLiveSessionController].
  final GeminiLiveSessionController? controller;

  /// Model identifier. Defaults to [LiveModels.gemini35LiveTranslatePreview].
  final String model;

  /// Source language BCP-47 code (e.g., `'ko-KR'`, `'en-US'`).
  final String sourceLanguageCode;

  /// Display label for the source language (e.g., `'한국어'`).
  final String sourceLanguageLabel;

  /// Target language BCP-47 code (e.g., `'en-US'`, `'ja-JP'`).
  final String targetLanguageCode;

  /// Display label for the target language (e.g., `'English'`).
  final String targetLanguageLabel;

  /// Whether to rotate the top target-language card 180° for face-to-face table mode.
  final bool faceToFaceMode;

  /// Callback when the user toggles face-to-face rotation mode in the default AppBar.
  final ValueChanged<bool>? onFaceToFaceModeChanged;

  /// Callback when the user taps the swap languages button.
  final VoidCallback? onSwapLanguages;

  /// Callback when the microphone button is tapped.
  final VoidCallback? onMicPressed;

  /// Whether the microphone is currently recording.
  /// If null, falls back to `controller.isUserSpeaking`.
  final bool? isRecording;

  /// Whether to automatically connect on initialization. Defaults to `false`.
  final bool autoConnect;

  /// Optional generation config override.
  final GenerationConfig? config;

  /// Optional custom header / AppBar builder.
  final PreferredSizeWidget? Function(
    BuildContext context,
    GeminiLiveSessionController controller,
  )?
  headerBuilder;

  /// Optional custom builder for the top (target language) pane.
  final GeminiLiveTranslatePaneBuilder? topPaneBuilder;

  /// Optional custom builder for the bottom (source language) pane.
  final GeminiLiveTranslatePaneBuilder? bottomPaneBuilder;

  /// Optional custom builder for the middle language swap bar.
  final GeminiLiveTranslateLanguageBarBuilder? languageBarBuilder;

  /// Optional custom builder for the bottom microphone / control area.
  final Widget Function(
    BuildContext context,
    GeminiLiveSessionController controller,
    bool isRecording,
    VoidCallback onToggleMic,
  )?
  controlsBuilder;

  /// Screen title shown in the default AppBar. Defaults to `'Live Interpreter'`.
  final String title;

  /// Background color override.
  final Color? backgroundColor;

  /// Adaptive layout mode for foldable devices, tablets, and desktops.
  ///
  /// When set to [GeminiLiveAdaptiveLayoutMode.auto] (the default):
  /// - Foldable Book posture (vertical hinge) or wide viewports (`width >= adaptiveBreakpoint`
  ///   when [faceToFaceMode] is `false`) arrange the panes side-by-side.
  /// - Foldable Tabletop / Flex posture (horizontal hinge) splits the target pane
  ///   above the hinge and the source pane + controls below the hinge.
  /// - Standard portrait screens or [faceToFaceMode] stack panes vertically.
  final GeminiLiveAdaptiveLayoutMode layoutMode;

  /// Width breakpoint at which [GeminiLiveAdaptiveLayoutMode.auto] switches to
  /// side-by-side dual panes when [faceToFaceMode] is `false`. Defaults to `840.0`.
  final double adaptiveBreakpoint;

  /// Whether to align panes around physical foldable hinges ([DisplayFeature]).
  /// Defaults to `true`.
  final bool respectFoldableHinge;

  /// Creates a dual-pane live translation view.
  const GeminiLiveTranslateSplitView({
    super.key,
    this.apiKey,
    this.controller,
    this.model = LiveModels.gemini35LiveTranslatePreview,
    this.sourceLanguageCode = 'ko-KR',
    this.sourceLanguageLabel = '한국어',
    this.targetLanguageCode = 'en-US',
    this.targetLanguageLabel = 'English',
    this.faceToFaceMode = false,
    this.onFaceToFaceModeChanged,
    this.onSwapLanguages,
    this.onMicPressed,
    this.isRecording,
    this.autoConnect = false,
    this.config,
    this.headerBuilder,
    this.topPaneBuilder,
    this.bottomPaneBuilder,
    this.languageBarBuilder,
    this.controlsBuilder,
    this.title = 'Live Interpreter',
    this.backgroundColor,
    this.layoutMode = GeminiLiveAdaptiveLayoutMode.auto,
    this.adaptiveBreakpoint = 840.0,
    this.respectFoldableHinge = true,
  }) : assert(
         apiKey != null || controller != null,
         'Either apiKey or controller must be provided to GeminiLiveTranslateSplitView.',
       );

  @override
  State<GeminiLiveTranslateSplitView> createState() =>
      _GeminiLiveTranslateSplitViewState();
}

class _GeminiLiveTranslateSplitViewState
    extends State<GeminiLiveTranslateSplitView> {
  late GeminiLiveSessionController _controller;
  late bool _ownsController;
  late bool _faceToFace;
  late String _sourceCode;
  late String _sourceLabel;
  late String _targetCode;
  late String _targetLabel;
  bool _internalRecording = false;

  GeminiLiveSessionController _createInternalController() {
    final genAI = GoogleGenAI(apiKey: widget.apiKey!);
    return GeminiLiveSessionController(liveService: genAI.live);
  }

  @override
  void initState() {
    super.initState();
    _faceToFace = widget.faceToFaceMode;
    _sourceCode = widget.sourceLanguageCode;
    _sourceLabel = widget.sourceLanguageLabel;
    _targetCode = widget.targetLanguageCode;
    _targetLabel = widget.targetLanguageLabel;

    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = _createInternalController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerUpdate);

    if (widget.autoConnect && !_controller.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connectTranslateSession();
      });
    }
  }

  @override
  void didUpdateWidget(GeminiLiveTranslateSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.faceToFaceMode != oldWidget.faceToFaceMode) {
      _faceToFace = widget.faceToFaceMode;
    }
    if (widget.sourceLanguageCode != oldWidget.sourceLanguageCode) {
      _sourceCode = widget.sourceLanguageCode;
    }
    if (widget.sourceLanguageLabel != oldWidget.sourceLanguageLabel) {
      _sourceLabel = widget.sourceLanguageLabel;
    }
    if (widget.targetLanguageCode != oldWidget.targetLanguageCode) {
      _targetCode = widget.targetLanguageCode;
    }
    if (widget.targetLanguageLabel != oldWidget.targetLanguageLabel) {
      _targetLabel = widget.targetLanguageLabel;
    }

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerUpdate);
      if (_ownsController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = _createInternalController();
        _ownsController = true;
      }
      _controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _connectTranslateSession() async {
    try {
      await _controller.connect(
        LiveConnectParameters(
          model: widget.model,
          callbacks: LiveCallbacks(),
          config: widget.config,
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          translationConfig: TranslationConfig(
            targetLanguageCode: _targetCode,
          ),
        ),
      );
    } catch (_) {}
  }

  void _handleSwapLanguages() {
    setState(() {
      final tmpCode = _sourceCode;
      final tmpLabel = _sourceLabel;
      _sourceCode = _targetCode;
      _sourceLabel = _targetLabel;
      _targetCode = tmpCode;
      _targetLabel = tmpLabel;
    });
    widget.onSwapLanguages?.call();
  }

  void _handleToggleFaceToFace() {
    setState(() {
      _faceToFace = !_faceToFace;
    });
    widget.onFaceToFaceModeChanged?.call(_faceToFace);
  }

  void _handleToggleMic() {
    if (widget.onMicPressed != null) {
      widget.onMicPressed!();
      return;
    }
    setState(() {
      _internalRecording = !_internalRecording;
    });
    if (!_internalRecording) {
      _controller.stopUserSpeaking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC));

    final userItems = _controller.transcripts
        .where((item) => item.role == 'user')
        .toList();
    final modelItems = _controller.transcripts
        .where((item) => item.role == 'model')
        .toList();

    final latestUserText = userItems.isNotEmpty ? userItems.last.text : null;
    final latestModelText = modelItems.isNotEmpty ? modelItems.last.text : null;
    final effectiveRecording =
        widget.isRecording ??
        (_controller.isUserSpeaking || _internalRecording);

    final Widget topPaneContent =
        widget.topPaneBuilder?.call(
          context,
          _targetCode,
          _targetLabel,
          latestModelText,
          modelItems,
          _controller.isModelSpeaking,
        ) ??
        _buildDefaultPane(
          context: context,
          isDark: isDark,
          languageCode: _targetCode,
          languageLabel: _targetLabel,
          latestText: latestModelText,
          placeholder: 'Translation will appear here',
          isActive: _controller.isModelSpeaking,
          isTargetPane: true,
        );

    final Widget bottomPaneContent =
        widget.bottomPaneBuilder?.call(
          context,
          _sourceCode,
          _sourceLabel,
          latestUserText,
          userItems,
          effectiveRecording,
        ) ??
        _buildDefaultPane(
          context: context,
          isDark: isDark,
          languageCode: _sourceCode,
          languageLabel: _sourceLabel,
          latestText: latestUserText,
          placeholder: 'Tap the microphone and start speaking',
          isActive: effectiveRecording,
          isTargetPane: false,
        );

    return Scaffold(
      backgroundColor: bg,
      appBar:
          widget.headerBuilder?.call(context, _controller) ??
          _buildDefaultAppBar(context, isDark),
      body: SafeArea(
        child: GeminiLiveResponsiveBuilder(
          builder: (context, viewport) {
            final effectiveMode =
                (_faceToFace &&
                    widget.layoutMode == GeminiLiveAdaptiveLayoutMode.auto &&
                    !viewport.isTabletopPosture)
                ? GeminiLiveAdaptiveLayoutMode.singlePane
                : widget.layoutMode;

            final primaryPaneWidget = _faceToFace
                ? RotatedBox(quarterTurns: 2, child: topPaneContent)
                : topPaneContent;

            final languageBarWidget =
                widget.languageBarBuilder?.call(
                  context,
                  _sourceCode,
                  _targetCode,
                  _handleSwapLanguages,
                ) ??
                _buildDefaultLanguageBar(context, isDark);

            final controlsWidget =
                widget.controlsBuilder?.call(
                  context,
                  _controller,
                  effectiveRecording,
                  _handleToggleMic,
                ) ??
                GeminiLiveMicButton(
                  isRecording: effectiveRecording,
                  onPressed: _handleToggleMic,
                  size: viewport.isShortHeight ? 48.0 : 60.0,
                );

            final hPad = viewport.isUltraNarrow ? 10.0 : 16.0;
            final bPad = viewport.isShortHeight ? 8.0 : 16.0;

            return GeminiLiveAdaptiveSplitView(
              mode: effectiveMode,
              breakpoint: widget.adaptiveBreakpoint,
              respectFoldableHinge: widget.respectFoldableHinge,
              spacing: viewport.isShortHeight ? 6.0 : 10.0,
              padding: EdgeInsets.fromLTRB(hPad, 8.0, hPad, bPad),
              primaryPane: primaryPaneWidget,
              centerWidget: languageBarWidget,
              secondaryPane: bottomPaneContent,
              bottomControls: controlsWidget,
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(BuildContext context, bool isDark) {
    final statusState = !_controller.isConnected
        ? (_controller.state == LiveSessionState.connecting
              ? GeminiLiveSessionState.connecting
              : GeminiLiveSessionState.disconnected)
        : (_controller.isModelSpeaking || _controller.isUserSpeaking
              ? GeminiLiveSessionState.inProgress
              : GeminiLiveSessionState.connected);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: [
        GeminiLiveStatusBadge(state: statusState),
        const SizedBox(width: 4),
        IconButton(
          tooltip: _faceToFace
              ? 'Exit face-to-face mode'
              : 'Face-to-face table mode',
          icon: Icon(
            Icons.screen_rotation_alt_rounded,
            size: 20,
            color: _faceToFace
                ? (isDark ? Colors.white : const Color(0xFF09090B))
                : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
          ),
          onPressed: _handleToggleFaceToFace,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDefaultLanguageBar(BuildContext context, bool isDark) {
    final pillBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF09090B);
    final subColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _sourceLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _handleSwapLanguages,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.swap_vert_rounded,
                size: 18,
                color: subColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _targetLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPane({
    required BuildContext context,
    required bool isDark,
    required String languageCode,
    required String languageLabel,
    required String? latestText,
    required String placeholder,
    required bool isActive,
    required bool isTargetPane,
  }) {
    final cardBg = isDark ? const Color(0xFF141417) : Colors.white;
    final borderColor = isActive
        ? (isDark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.18))
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06));
    final titleColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final bodyColor = isDark ? Colors.white : const Color(0xFF09090B);
    final placeholderColor = isDark
        ? const Color(0xFF52525B)
        : const Color(0xFFA1A1AA);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactPane =
            constraints.hasBoundedHeight && constraints.maxHeight < 140.0;
        final pad = isCompactPane ? 12.0 : 20.0;
        final hasText = latestText != null && latestText.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.0 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            languageLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          languageCode,
                          style: TextStyle(
                            color: titleColor.withValues(alpha: 0.65),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    GeminiLiveWaveform(
                      width: 30,
                      barCount: 5,
                      height: 16,
                      barWidth: 2.5,
                      spacing: 2.0,
                      color: bodyColor.withValues(alpha: 0.75),
                    ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      hasText ? latestText : placeholder,
                      maxLines: isCompactPane ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasText ? bodyColor : placeholderColor,
                        fontSize: hasText
                            ? (isCompactPane ? 17 : 22)
                            : (isCompactPane ? 14 : 17),
                        fontWeight: hasText ? FontWeight.w600 : FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
