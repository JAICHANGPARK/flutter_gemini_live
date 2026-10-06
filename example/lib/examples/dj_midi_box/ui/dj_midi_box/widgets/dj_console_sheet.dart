import 'package:flutter/material.dart';

import '../view_models/dj_midi_box_view_model.dart';
import 'dj_console_panel.dart';

/// Opens the console (prompt / settings / logs) as a bottom sheet on narrow
/// screens.
void showDjMobileConsoleSheet(
  BuildContext context,
  DjMidiBoxViewModel viewModel,
  ScrollController logScrollController,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF13092C),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: DjConsolePanel(
          viewModel: viewModel,
          logScrollController: logScrollController,
        ),
      );
    },
  );
}
