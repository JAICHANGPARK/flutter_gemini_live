import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'latex_markdown.dart';

/// Markdown body with `$...$` / `$$...$$` LaTeX rendering and the tutor's
/// dark-theme styling.
class MathMarkdown extends StatelessWidget {
  const MathMarkdown(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _preprocessMathText(text),
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [LatexInlineSyntax()],
      blockSyntaxes: const [LatexBlockSyntax()],
      builders: {
        'latex': LatexElementBuilder(),
        'latex-block': LatexElementBuilder(isBlock: true),
      },
      styleSheet: _buildMarkdownStyleSheet(),
    );
  }

  static MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        color: Colors.amber,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      p: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      code: const TextStyle(
        color: Colors.amberAccent,
        fontFamily: 'monospace',
        backgroundColor: Colors.black38,
        fontSize: 12,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      blockquote: const TextStyle(
        color: Colors.greenAccent,
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static String _preprocessMathText(String text) {
    // Convert \[ ... \] to $$ ... $$
    var res = text.replaceAllMapped(
      RegExp(r'\\\[([\s\S]*?)\\\]'),
      (m) => '\n\$\$\n${m[1]?.trim()}\n\$\$\n',
    );
    // Convert \( ... \) to $ ... $
    res = res.replaceAllMapped(
      RegExp(r'\\\(([\s\S]*?)\\\)'),
      (m) => ' \$${m[1]?.trim()}\$ ',
    );
    return res;
  }
}
