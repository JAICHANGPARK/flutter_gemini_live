import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import 'view_models/realtime_media_view_model.dart';
import 'widgets/control_panel.dart';
import 'widgets/log_section.dart';
import 'widgets/section_divider.dart';

/// Demo page for realtime audio/video input features.
class RealtimeMediaDemoPage extends StatefulWidget {
  const RealtimeMediaDemoPage({super.key});

  @override
  State<RealtimeMediaDemoPage> createState() => _RealtimeMediaDemoPageState();
}

class _RealtimeMediaDemoPageState extends State<RealtimeMediaDemoPage>
    with WidgetsBindingObserver {
  late final RealtimeMediaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = RealtimeMediaViewModel();
    _viewModel.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Realtime Media Demo'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GeminiLiveStatusBadge.fromFlags(
                  isConnected: vm.isConnected,
                  isConnecting: vm.isConnecting,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;
              final compact =
                  constraints.maxHeight < 760 || constraints.maxWidth < 900;

              if (isWide) {
                final controlsWidth = (constraints.maxWidth * 0.42)
                    .clamp(360.0, 520.0)
                    .toDouble();

                return Row(
                  children: [
                    SizedBox(
                      width: controlsWidth,
                      child: SingleChildScrollView(
                        child: ControlPanel(viewModel: vm, compact: compact),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: LogSection(viewModel: vm)),
                  ],
                );
              }

              final logHeight = (constraints.maxHeight * 0.34)
                  .clamp(180.0, 300.0)
                  .toDouble();

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: ControlPanel(viewModel: vm, compact: compact),
                    ),
                  ),
                  const SectionDivider(),
                  Expanded(
                    child: SizedBox(
                      height: logHeight,
                      child: LogSection(viewModel: vm),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
