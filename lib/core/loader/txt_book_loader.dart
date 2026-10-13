import 'dart:convert';
import 'dart:io';
import 'package:charset/charset.dart';
import '../errors/failures.dart';
import '../models/book.dart';
import 'book_loader.dart';

/// TXT 加载器。作为最底层的格式实现，整篇读入后切成章节。
class TxtBookLoader implements BookLoader {
  const TxtBookLoader();

  @override
  bool supports(BookFormat format) => format == BookFormat.txt;

  @override
  Future<BookDocument> load(Book book) async {
    final file = File(book.path);
    if (!await file.exists()) {
      throw const BookLoadFailure('文件不存在');
    }
    final text = decodeText(await file.readAsBytes());
    final chapters = _splitChapters(text, book);
    return BookDocument(book: book, chapters: chapters);
  }

  /// 将纯文本切分为章节：先按空行分段，再识别章标题（第X章 / Chapter N 等）
  /// 作为新章起点；无可识别章节时回退为单章（全部段落拼入正文）。
  List<BookChapter> _splitChapters(String text, Book book) {
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return [
        BookChapter(id: '${book.id}#0', title: book.title, content: '（空文件）'),
      ];
    }

    final chapterRe = RegExp(
      r'^\s*(第\s*[0-9零一二三四五六七八九十百千]+\s*[章卷回部篇节]|Chapter\s+[0-9]+)',
      caseSensitive: false,
    );

    final chapters = <BookChapter>[];
    var currentTitle = book.title;
    final currentParas = <String>[];

    void flush() {
      if (currentParas.isEmpty) return;
      chapters.add(BookChapter(
        id: '${book.id}#${chapters.length}',
        title: currentTitle,
        content: currentParas.join('\n\n'),
      ));
      currentParas.clear();
    }

    for (final p in paragraphs) {
      if (chapterRe.hasMatch(p)) {
        flush();
        currentTitle = p.replaceAll(RegExp(r'\s+'), ' ').trim();
      } else {
        currentParas.add(p);
      }
    }
    flush();

    if (chapters.isEmpty) {
      chapters.add(BookChapter(
        id: '${book.id}#0',
        title: book.title,
        content: paragraphs.join('\n\n'),
      ));
    }
    return chapters;
  }
}

/// 将字节按常见编码解码为字符串，依次尝试：
/// UTF-8（含 BOM）、GBK（中文 TXT 常见编码）、容错 UTF-8 兜底，避免崩溃。
String decodeText(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3));
  }
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } catch (_) {
    // 非严格 UTF-8，继续尝试 GBK。
  }
  try {
    return const GbkCodec(allowMalformed: true).decode(bytes);
  } catch (_) {
    // 仍失败则兜底，避免抛出导致加载失败。
  }
  return utf8.decode(bytes, allowMalformed: true);
}
