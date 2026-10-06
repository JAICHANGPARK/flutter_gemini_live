import 'package:example/app_settings_dialog.dart';
import 'package:flutter/material.dart';

import 'view_models/translation_view_model.dart';
import 'widgets/translation_app_bar.dart';
import 'widgets/translation_bottom_bar.dart';
import 'widgets/translation_dual_flip_layout.dart';
import 'widgets/translation_language_bar.dart';
import 'widgets/translation_standard_chat_layout.dart';

/// Real-time two-way interpreter powered by Gemini Live Translate
/// (`gemini-3.5-live-translate-preview`).
///
/// This is the view: it builds the layout from [TranslationViewModel] state and
/// shows dialogs and snackbars on the view model's behalf.
class LiveTranslationPage extends StatefulWidget {
  const LiveTranslationPage({super.key});

  @override
  State<LiveTranslationPage> createState() => _LiveTranslationPageState();
}

class _LiveTranslationPageState extends State<LiveTranslationPage> {
  late final TranslationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TranslationViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup;
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  Future<void> _openSettings() async {
    final updated = await AppSettingsDialog.show(context);
    if (updated == true && mounted) {
      await _viewModel.reloadAfterSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: TranslationAppBar(
            viewModel: vm,
            onOpenSettings: _openSettings,
          ),
          body: Column(
            children: [
              // 1. Language & Configuration Bar
              TranslationLanguageBar(viewModel: vm),

              // 2. Main Content Area (Dual Flip Mode vs Standard Chat Mode)
              Expanded(
                child: vm.isDualFlipMode
                    ? TranslationDualFlipLayout(viewModel: vm)
                    : TranslationStandardChatLayout(viewModel: vm),
              ),

              // 3. Waveform & Controls Bottom Bar
              TranslationBottomBar(viewModel: vm),
            ],
          ),
        );
      },
    );
  }
}
