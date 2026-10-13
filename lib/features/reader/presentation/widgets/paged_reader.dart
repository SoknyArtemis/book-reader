import 'package:flutter/material.dart';
import '../../../../core/models/book.dart';
import 'txt_paginator.dart';

/// 分页阅读器：将全文按可视区域测量切分为多页，用 [PageView] 翻页。
/// v1 使用直切翻页（无仿真动画）。
class PagedReader extends StatefulWidget {
  const PagedReader({
    super.key,
    required this.chapters,
    required this.fontSize,
  });
  final List<BookChapter> chapters;
  final double fontSize;

  @override
  State<PagedReader> createState() => _PagedReaderState();
}

class _PagedReaderState extends State<PagedReader> {
  List<String> _pages = const [];
  String? _cacheKey;

  // 仅当字号、可视尺寸或正文内容变化时重算分页，避免每次重建都全量重测。
  String _key(double w, double h) =>
      '${widget.fontSize}|$w|$h|${widget.chapters.length}|'
      '${widget.chapters.fold(0, (s, c) => s + c.content.length + c.title.length)}';

  @override
  Widget build(BuildContext context) {
    final fullText = widget.chapters
        .map((c) => '${c.title}\n\n${c.content}')
        .join('\n\n');
    final style = TextStyle(fontSize: widget.fontSize, height: 1.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final key = _key(
          constraints.maxWidth - 32,
          constraints.maxHeight - 32,
        );
        if (key != _cacheKey) {
          _pages = TxtPaginator.paginate(
            text: fullText,
            style: style,
            maxWidth: constraints.maxWidth - 32,
            maxHeight: constraints.maxHeight - 32,
          );
          _cacheKey = key;
        }
        return PageView.builder(
          pageSnapping: true,
          itemCount: _pages.length,
          itemBuilder: (context, index) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(_pages[index], style: style),
          ),
        );
      },
    );
  }
}
