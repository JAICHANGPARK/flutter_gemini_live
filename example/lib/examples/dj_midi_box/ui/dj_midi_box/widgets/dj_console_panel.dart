import 'package:flutter/material.dart';

import '../view_models/dj_midi_box_view_model.dart';
import 'dj_logs_tab.dart';
import 'dj_prompt_tab.dart';
import 'dj_settings_tab.dart';

// ==========================================================================
// Left Console Panel: Custom Prompt, Settings & Logs
// ==========================================================================

class DjConsolePanel extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;
  final ScrollController logScrollController;

  const DjConsolePanel({
    super.key,
    required this.viewModel,
    required this.logScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: const Color(0xFF13092C).withAlpha(250),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFFA855F7), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'DJ CONSOLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFA855F7).withAlpha(100),
                      ),
                    ),
                    child: Text(
                      viewModel.isPlaying ? 'STREAMING' : 'IDLE',
                      style: const TextStyle(
                        color: Color(0xFFA855F7),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.black.withAlpha(40),
              child: const TabBar(
                indicatorColor: Color(0xFFA855F7),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.edit_note, size: 16), text: 'PROMPT'),
                  Tab(
                    icon: Icon(Icons.settings_input_component, size: 16),
                    text: 'SETTINGS',
                  ),
                  Tab(icon: Icon(Icons.terminal, size: 16), text: 'LOGS'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  buildDjPromptTab(context, viewModel),
                  buildDjSettingsTab(context, viewModel),
                  buildDjLogsTab(viewModel, logScrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
