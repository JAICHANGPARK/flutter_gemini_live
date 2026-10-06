import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';

/// Floating pill that reopens the hidden notes sheet (shows the saved count).
class ShowNotesButton extends StatelessWidget {
  const ShowNotesButton({super.key, required this.viewModel});

  final MathTutorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageController.instance.currentLanguage;
    final solutionHistory = viewModel.solutionHistory;
    return Positioned(
      left: 16,
      top: 12,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => viewModel.isBottomSheetVisible = true,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    size: 16,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    MathTutorI18n(lang).btnShowSheet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (solutionHistory.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${solutionHistory.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
