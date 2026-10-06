import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import 'math_tutor_i18n.dart';
import 'view_models/math_tutor_notice.dart';
import 'view_models/math_tutor_view_model.dart';
import 'widgets/camera_pane.dart';
import 'widgets/clear_history_dialog.dart';
import 'widgets/curriculum_selector_bar.dart';
import 'widgets/math_tutor_app_bar.dart';
import 'widgets/math_tutor_snack_bar.dart';
import 'widgets/show_notes_button.dart';
import 'widgets/solution_board_pane.dart';
import 'widgets/solution_bottom_sheet.dart';
import 'widgets/system_instruction_dialog.dart';

/// Fullscreen real-time Multimodal Math Tutor powered by
/// Gemini 3.8 Live Extended Thinking (`gemini-3.8-live-extended-thinking`).
///
/// This is the view: it owns only UI-bound objects (animation / sheet
/// controllers), builds the layout from [MathTutorViewModel] state and shows
/// dialogs and snackbars on the view model's behalf.
class LiveMathTutorPage extends StatefulWidget {
  const LiveMathTutorPage({super.key});

  @override
  State<LiveMathTutorPage> createState() => _LiveMathTutorPageState();
}

class _LiveMathTutorPageState extends State<LiveMathTutorPage>
    with SingleTickerProviderStateMixin {
  late final MathTutorViewModel _viewModel;
  late final AnimationController _pulseAnimController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _viewModel = MathTutorViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup;

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _viewModel.init();
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _sheetController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(MathTutorNotice notice) {
    if (!mounted) return;
    showMathTutorSnackBar(context, notice);
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  Future<void> _openSettings() async {
    final changed = await AppSettingsDialog.show(context);
    if (changed == true && mounted) {
      await _viewModel.connectSession();
    }
  }

  Future<void> _confirmClearHistory() async {
    final i18n = MathTutorI18n(AppLanguageController.instance.currentLanguage);
    final confirmed = await showClearHistoryDialog(context, i18n);
    if (confirmed == true && mounted) {
      await _viewModel.clearHistory();
    }
  }

  Future<void> _editSystemInstruction() async {
    final i18n = MathTutorI18n(AppLanguageController.instance.currentLanguage);
    final text = await showSystemInstructionDialog(
      context,
      i18n: i18n,
      initialText: _viewModel.customSystemInstruction,
    );
    if (text != null && mounted) {
      await _viewModel.applySystemInstruction(text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        final isWide = MediaQuery.of(context).size.width >= 840;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: MathTutorAppBar(
            viewModel: vm,
            pulse: _pulseAnimController,
            onShowSystemInstruction: _editSystemInstruction,
            onOpenSettings: _openSettings,
          ),
          body: SafeArea(
            child: Column(
              children: [
                CurriculumSelectorBar(
                  selected: vm.curriculumLevel,
                  onSelected: vm.switchCurriculum,
                ),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: vm.isCameraExpanded ? 7 : 5,
                              child: CameraPane(viewModel: vm),
                            ),
                            const VerticalDivider(
                              width: 1,
                              color: Colors.white12,
                            ),
                            Expanded(
                              flex: vm.isCameraExpanded ? 3 : 5,
                              child: SolutionBoardPane(
                                viewModel: vm,
                                pulse: _pulseAnimController,
                                onClearHistory: _confirmClearHistory,
                              ),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // Full-bleed camera pane with dynamic bottom padding based on sheet visibility
                                Positioned.fill(
                                  child: CameraPane(
                                    viewModel: vm,
                                    bottomPadding: vm.isBottomSheetVisible
                                        ? (constraints.maxHeight * 0.16).clamp(
                                            70.0,
                                            110.0,
                                          )
                                        : 24.0,
                                  ),
                                ),

                                // Height-adjustable Draggable Bottom Sheet for Solutions & Thinking Scratchpad
                                if (vm.isBottomSheetVisible)
                                  SolutionBottomSheet(
                                    viewModel: vm,
                                    pulse: _pulseAnimController,
                                    sheetController: _sheetController,
                                    onClearHistory: _confirmClearHistory,
                                  ),

                                // Floating Reopen Button when bottom sheet is hidden
                                if (!vm.isBottomSheetVisible)
                                  ShowNotesButton(viewModel: vm),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
