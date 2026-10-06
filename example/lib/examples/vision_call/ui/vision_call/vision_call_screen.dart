import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import 'view_models/vision_call_notice.dart';
import 'view_models/vision_call_view_model.dart';
import 'vision_call_i18n.dart';
import 'widgets/book_mode_layout.dart';
import 'widgets/camera_viewfinder.dart';
import 'widgets/chat_transcript_sheet.dart';
import 'widgets/standard_layout.dart';
import 'widgets/tabletop_layout.dart';
import 'widgets/vision_call_header.dart';
import 'widgets/vision_call_snack_bar.dart';
import 'widgets/vision_control_bar.dart';

/// Fullscreen real-time multimodal Vision & Voice call page
/// for universal real-time multimodal interaction (Project Astra style).
///
/// This is the view: it owns only UI-bound objects (the dots animation
/// controller, the lifecycle observer) and builds the layout from
/// [VisionCallViewModel] state.
class LiveVisionCallPage extends StatefulWidget {
  const LiveVisionCallPage({
    super.key,
    this.agentTitle,
    this.customSystemPrompt,
  });

  final String? agentTitle;
  final String? customSystemPrompt;

  @override
  State<LiveVisionCallPage> createState() => _LiveVisionCallPageState();
}

class _LiveVisionCallPageState extends State<LiveVisionCallPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final VisionCallViewModel _viewModel;

  // Animation controller for bottom visualizer dots
  late final AnimationController _dotsAnimController;

  @override
  void initState() {
    super.initState();
    _viewModel =
        VisionCallViewModel(customSystemPrompt: widget.customSystemPrompt)
          ..onNotice = _showNotice
          ..requestApiKeySetup = _requestApiKeySetup;
    WidgetsBinding.instance.addObserver(this);

    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _viewModel.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dotsAnimController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.didChangeAppLifecycleState(state);
  }

  void _showNotice(VisionCallNotice notice) {
    if (!mounted) return;
    showVisionCallSnackBar(context, notice);
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  Future<void> _openSettings() async {
    final updated = await AppSettingsDialog.show(context);
    if (updated == true && mounted) {
      await _viewModel.onSettingsChanged();
    }
  }

  void _endCall() {
    _viewModel.endCall();
    Navigator.of(context).pop();
  }

  void _openChatSheet() {
    final i18n = VisionCallI18n(AppLanguageController.instance.currentLanguage);
    showChatTranscriptSheet(
      context,
      i18n: i18n,
      chatHistory: _viewModel.chatHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLanguageController.instance,
        _viewModel,
      ]),
      builder: (context, _) {
        final currentLang = AppLanguageController.instance.currentLanguage;
        final i18n = VisionCallI18n(currentLang);
        final vm = _viewModel;

        // Deep forest green background theme matching the user's screenshot
        const themeBgColor = Color(0xFF091E14);
        final foldableInfo = FoldableLayoutInfo.of(context);

        final header = VisionCallHeader(
          viewModel: vm,
          i18n: i18n,
          agentTitle: widget.agentTitle,
          onOpenSettings: _openSettings,
        );
        final viewfinder = CameraViewfinder(viewModel: vm, i18n: i18n);
        final controlBar = VisionControlBar(
          viewModel: vm,
          i18n: i18n,
          dotsAnimation: _dotsAnimController,
          onOpenChat: _openChatSheet,
          onEndCall: _endCall,
        );

        // 1. Tabletop / Flex Mode (Foldable device half-opened on desk)
        if (foldableInfo.isTabletop) {
          return TabletopLayout(
            backgroundColor: themeBgColor,
            i18n: i18n,
            chatHistory: vm.chatHistory,
            header: header,
            viewfinder: viewfinder,
            controlBar: controlBar,
          );
        }

        // 2. Dual-Screen Book Mode (Surface Duo or Galaxy Fold unfolded wide side-by-side)
        if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
          return BookModeLayout(
            backgroundColor: themeBgColor,
            i18n: i18n,
            chatHistory: vm.chatHistory,
            hingeWidth: foldableInfo.hingeBounds?.width,
            header: header,
            viewfinder: viewfinder,
            controlBar: controlBar,
          );
        }

        // 3. Standard Layout
        return StandardLayout(
          backgroundColor: themeBgColor,
          subtitle: vm.liveSubtitleNotifier,
          header: header,
          viewfinder: viewfinder,
          controlBar: controlBar,
        );
      },
    );
  }
}
