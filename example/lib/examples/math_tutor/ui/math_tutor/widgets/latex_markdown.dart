import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Inline syntax for TeX formulas: $...$
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'(?<!\\)\$((?:\\\$|[^$])+?)(?<!\\)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match[1] ?? '';
    final el = md.Element.text('latex', raw);
    parser.addNode(el);
    return true;
  }
}

/// Block syntax for TeX display formulas: $$...$$
class LatexBlockSyntax extends md.BlockSyntax {
  static final _pattern = RegExp(
    r'^\$\$\s*([\s\S]*?)\s*\$\$$',
    multiLine: true,
  );

  @override
  RegExp get pattern => _pattern;

  const LatexBlockSyntax();

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match != null) {
      parser.advance();
      return md.Element.text('latex-block', match[1] ?? '');
    }
    if (parser.current.content.startsWith(r'$$')) {
      final childLines = <String>[];
      final firstLine = parser.current.content.substring(2);
      parser.advance();
      if (firstLine.endsWith(r'$$') && firstLine.length >= 2) {
        return md.Element.text(
          'latex-block',
          firstLine.substring(0, firstLine.length - 2),
        );
      }
      childLines.add(firstLine);
      while (!parser.isDone) {
        final line = parser.current.content;
        if (line.endsWith(r'$$')) {
          childLines.add(line.substring(0, line.length - 2));
          parser.advance();
          break;
        }
        childLines.add(line);
        parser.advance();
      }
      return md.Element.text('latex-block', childLines.join('\n'));
    }
    return null;
  }
}

/// Element builder rendering TeX formulas with FlutterMath.
class LatexElementBuilder extends MarkdownElementBuilder {
  final bool isBlock;
  LatexElementBuilder({this.isBlock = false});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent.trim();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isBlock ? 6.0 : 1.0,
          horizontal: 2.0,
        ),
        child: Math.tex(
          tex,
          textStyle:
              (preferredStyle ??
                      const TextStyle(color: Colors.white, fontSize: 14))
                  .copyWith(
                    color: isBlock ? Colors.amberAccent : Colors.cyanAccent,
                  ),
          mathStyle: isBlock ? MathStyle.display : MathStyle.text,
          onErrorFallback: (err) => Text(
            isBlock ? '\$\$\n$tex\n\$\$' : '\$$tex\$',
            style: TextStyle(
              color: Colors.amber.shade200,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
