import 'package:flutter/material.dart';
import '../../../../core/models/book.dart';

/// 滚动阅读器：将章节顺序排布为可纵向滚动的列表。
class ScrollReader extends StatelessWidget {
  const ScrollReader({
    super.key,
    required this.chapters,
    required this.fontSize,
  });
  final List<BookChapter> chapters;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = <Widget>[];
    for (final ch in chapters) {
      blocks.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SelectableText(ch.title, style: theme.textTheme.titleMedium),
      ));
      final paragraphs = ch.content
          .split(RegExp(r'\n\s*\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final p in paragraphs) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText(p, style: TextStyle(fontSize: fontSize, height: 1.6)),
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: blocks,
    );
  }
}
