import 'dart:math';
import 'package:flutter/material.dart';

/// 纯文本分页器。
///
/// 给定文本、样式与可视区域尺寸，按段落测量并切分为多页，
/// 保证每页内容不超过可视高度（单段超高时可溢出，由页面内部滚动兜底）。
class TxtPaginator {
  TxtPaginator._();

  static List<String> paginate({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    double paragraphSpacing = 8,
  }) {
    final width = max(1.0, maxWidth);
    final height = max(1.0, maxHeight);
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final pages = <String>[];
    final buffer = <String>[];
    var usedHeight = 0.0;

    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..textAlign = TextAlign.left;

    void flush() {
      if (buffer.isNotEmpty) {
        pages.add(buffer.join('\n\n'));
        buffer.clear();
        usedHeight = 0;
      }
    }

    for (final para in paragraphs) {
      tp
        ..text = TextSpan(text: para, style: style)
        ..layout(maxWidth: width);
      final paraHeight = tp.height + paragraphSpacing;

      if (usedHeight + paraHeight > height && buffer.isNotEmpty) {
        flush();
        tp
          ..text = TextSpan(text: para, style: style)
          ..layout(maxWidth: width);
      }
      buffer.add(para);
      usedHeight += paraHeight;
    }
    flush();

    if (pages.isEmpty) pages.add('');
    return pages;
  }
}
