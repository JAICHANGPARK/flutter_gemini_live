import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/math_curriculum_level.dart';

/// Horizontally scrolling chip bar for choosing the curriculum / subject focus.
class CurriculumSelectorBar extends StatelessWidget {
  const CurriculumSelectorBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MathCurriculumLevel selected;
  final ValueChanged<MathCurriculumLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageController.instance.currentLanguage;
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MathCurriculumLevel.values.map((lvl) {
            final isSelected = selected == lvl;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  lvl.badgeIcon,
                  size: 16,
                  color: isSelected ? Colors.black : Colors.amberAccent,
                ),
                label: Text(
                  lvl.label(lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.amberAccent,
                backgroundColor: const Color(0xFF334155),
                onSelected: (_) => onSelected(lvl),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
