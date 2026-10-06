import 'package:flutter/material.dart';

import '../../../domain/models/translation_languages.dart';

/// Compact language picker used for "my language" / "partner language".
class TranslationLanguageDropdown extends StatelessWidget {
  const TranslationLanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;

  /// `null` disables the dropdown (while connected).
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      isDense: true,
      underline: const SizedBox(),
      items: kTranslationLanguages.map((lang) {
        return DropdownMenuItem<String>(
          value: lang['code'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang['flag'] ?? '', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(
                lang['name']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
