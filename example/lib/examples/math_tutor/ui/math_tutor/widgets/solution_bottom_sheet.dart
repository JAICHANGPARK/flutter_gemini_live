import 'package:flutter/material.dart';

import '../view_models/math_tutor_view_model.dart';
import 'solution_board_pane.dart';

/// Draggable bottom sheet hosting the notes board on narrow screens.
class SolutionBottomSheet extends StatelessWidget {
  const SolutionBottomSheet({
    super.key,
    required this.viewModel,
    required this.pulse,
    required this.sheetController,
    required this.onClearHistory,
  });

  final MathTutorViewModel viewModel;
  final Animation<double> pulse;
  final DraggableScrollableController sheetController;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.32,
      minChildSize: 0.14,
      maxChildSize: 0.90,
      snap: true,
      snapSizes: const [0.14, 0.32, 0.90],
      builder: (context, sheetScrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                spreadRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SolutionBoardPane(
              viewModel: viewModel,
              pulse: pulse,
              onClearHistory: onClearHistory,
              scrollController: sheetScrollController,
              showDragHandle: true,
              onCloseSheet: () => viewModel.isBottomSheetVisible = false,
            ),
          ),
        );
      },
    );
  }
}
