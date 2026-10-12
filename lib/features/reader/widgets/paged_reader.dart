import 'package:flutter/material.dart';
import '../../../core/models/book.dart';
import 'txt_paginator.dart';

/// 分页阅读器：将全文按可视区域测量切分为多页，用 [PageView] 翻页。
/// v1 使用直切翻页（无仿真动画）。
class PagedReader extends StatelessWidget {
  const PagedReader({
    super.key,
    required this.chapters,
    required this.fontSize,
  });
  final List<BookChapter> chapters;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final fullText = chapters
        .map((c) => '${c.title}\n\n${c.content}')
        .join('\n\n');
    final style = TextStyle(fontSize: fontSize, height: 1.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pages = TxtPaginator.paginate(
          text: fullText,
          style: style,
          maxWidth: constraints.maxWidth - 32,
          maxHeight: constraints.maxHeight - 32,
        );
        return PageView.builder(
          pageSnapping: true,
          itemCount: pages.length,
          itemBuilder: (context, index) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(pages[index], style: style),
          ),
        );
      },
    );
  }
}
