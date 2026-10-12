import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../errors/failures.dart';
import '../models/book.dart';
import 'book_loader.dart';

/// EPUB 加载器。
///
/// v1 策略：EPUB 本质是 zip + XHTML，这里解析 OPF 获取元数据与章节顺序，
/// 并把每章 XHTML 抽取为纯文本，复用与 TXT 相同的阅读渲染管线。
/// 富文本（图片/样式/链接）渲染作为后续增强，不影响当前架构。
class EpubBookLoader implements BookLoader {
  const EpubBookLoader();

  @override
  bool supports(BookFormat format) => format == BookFormat.epub;

  @override
  Future<BookDocument> load(Book book) async {
    try {
      final bytes = await File(book.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileMap = {for (final f in archive.files) f.name: f};

      final container = fileMap['META-INF/container.xml'];
      if (container == null || container.content == null) {
        throw const BookLoadFailure('无效的 EPUB：缺少 container.xml');
      }
      final opfPath = _findOpfPath(_decode(container.content!));
      final opfFile = fileMap[opfPath];
      if (opfFile == null || opfFile.content == null) {
        throw const BookLoadFailure('无效的 EPUB：找不到 OPF 文件');
      }

      final opfDir = p.posix.dirname(opfPath);
      final opfText = _decode(opfFile.content!);

      final meta = _parseMetadata(opfText);
      final chapterRefs = _parseSpine(opfText, opfDir);

      final chapters = <BookChapter>[];
      for (var i = 0; i < chapterRefs.length; i++) {
        final entry = fileMap[chapterRefs[i].path];
        if (entry == null || entry.content == null) continue;
        final html = _decode(entry.content!);
        final text = _extractText(html);
        if (text.trim().isEmpty) continue;
        chapters.add(BookChapter(
          id: '${book.id}#$i',
          title: chapterRefs[i].title ?? '第 ${i + 1} 章',
          content: text.trim(),
        ));
      }

      if (chapters.isEmpty) {
        throw const BookLoadFailure('EPUB 中未找到可读内容');
      }

      final loadedBook = book.copyWith(
        title: meta.title ?? book.title,
        author: meta.author,
      );
      return BookDocument(book: loadedBook, chapters: chapters);
    } catch (e) {
      if (e is BookLoadFailure) rethrow;
      throw BookLoadFailure('无法解析 EPUB：$e');
    }
  }

  String _decode(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

  String _findOpfPath(String containerXml) {
    final match = RegExp(r'full-path="([^"]+)"').firstMatch(containerXml);
    if (match == null) {
      throw const BookLoadFailure('无效的 EPUB：container 中无 rootfile');
    }
    return match.group(1)!;
  }

  ({String title, String? author}) _parseMetadata(String opf) {
    String? title;
    final t = RegExp(r'<dc:title[^>]*>(.*?)</dc:title>', dotAll: true).firstMatch(opf);
    if (t != null) title = _stripTags(t.group(1)!).trim();
    title ??= RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
        .firstMatch(opf)
        ?.group(1)
        ?.trim();

    String? author;
    final a = RegExp(r'<dc:creator[^>]*>(.*?)</dc:creator>', dotAll: true).firstMatch(opf);
    if (a != null) author = _stripTags(a.group(1)!).trim();

    return (title: title ?? '未知书名', author: author);
  }

  List<({String path, String? title})> _parseSpine(String opf, String opfDir) {
    final manifest = <String, String>{}; // id -> href
    for (final m in RegExp(r'<item\b([^>]*)/>', caseSensitive: false, dotAll: true)
        .allMatches(opf)) {
      final attrs = m.group(1)!;
      final id = _attr(attrs, 'id');
      final href = _attr(attrs, 'href');
      if (id != null && href != null) manifest[id] = href;
    }

    final result = <({String path, String? title})>[];
    for (final s in RegExp(r'<itemref\b([^>]*)/>', caseSensitive: false, dotAll: true)
        .allMatches(opf)) {
      final idref = _attr(s.group(1)!, 'idref');
      if (idref == null) continue;
      final href = manifest[idref];
      if (href == null) continue;
      final resolved = p.posix.normalize(p.posix.join(opfDir, href));
      result.add((path: resolved, title: null));
    }
    return result;
  }

  String? _attr(String tag, String name) {
    final double = RegExp('$name="([^"]*)"').firstMatch(tag);
    if (double != null) return double.group(1);
    final single = RegExp("$name='([^']*)'").firstMatch(tag);
    return single?.group(1);
  }

  String _stripTags(String html) => html.replaceAll(RegExp(r'<[^>]+>'), ' ');

  /// 从 XHTML 抽取纯文本（v1 用正则，规避 DTD/实体解析问题，稳定且足够）。
  String _extractText(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)));
    text = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    return text.trim();
  }
}
