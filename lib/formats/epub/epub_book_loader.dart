import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../../core/errors/failures.dart';
import '../../core/models/book.dart';
import '../../core/loader/book_loader.dart';

/// EPUB 加载器（解耦格式模块）。
///
/// 该模块独立于核心层，仅依赖核心的 [BookLoader] 契约与领域模型，
/// 不引用 TXT 或其它格式的实现，可单独移除而不影响核心。
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
      final fileMap = {for (final f in archive.files) _normPath(f.name): f};

      final container = fileMap[_normPath('META-INF/container.xml')];
      if (container == null) {
        throw const BookLoadFailure('无效的 EPUB：缺少 container.xml');
      }
      final opfPath = _findOpfPath(_decode(container.content));
      final opfFile = fileMap[_normPath(opfPath)];
      if (opfFile == null) {
        throw const BookLoadFailure('无效的 EPUB：找不到 OPF 文件');
      }

      final opfDir = p.posix.dirname(opfPath);
      final opfText = _decode(opfFile.content);

      final meta = _parseMetadata(opfText);
      final chapterRefs = _parseSpine(opfText, opfDir);

      final chapters = <BookChapter>[];
      for (var i = 0; i < chapterRefs.length; i++) {
        final entry = fileMap[_normPath(chapterRefs[i].path)];
        if (entry == null) continue;
        final html = _decode(entry.content);
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
        title: meta.title,
        author: meta.author,
      );
      return BookDocument(book: loadedBook, chapters: chapters);
    } catch (e) {
      if (e is BookLoadFailure) rethrow;
      throw BookLoadFailure('无法解析 EPUB：$e');
    }
  }

  String _decode(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

  /// 归档内路径归一化：反斜杠→斜杠、去前导斜杠、转小写，规避大小写/前导 / 差异。
  String _normPath(String name) =>
      name.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '').toLowerCase();

  String _findOpfPath(String containerXml) {
    final match = RegExp(r'full-path="([^"]+)"').firstMatch(containerXml);
    if (match == null) {
      throw const BookLoadFailure('无效的 EPUB：container 中无 rootfile');
    }
    return match.group(1)!;
  }

  ({String title, String? author}) _parseMetadata(String opf) {
    String? title;
    final t = RegExp(r'<dc:title[^>]*>(.*?)</dc:title>', dotAll: true)
        .firstMatch(opf);
    if (t != null) title = _stripTags(t.group(1)!).trim();

    String? author;
    final a = RegExp(r'<dc:creator[^>]*>(.*?)</dc:creator>', dotAll: true)
        .firstMatch(opf);
    if (a != null) author = _stripTags(a.group(1)!).trim();

    return (title: title ?? '未知书名', author: author);
  }

  List<({String path, String? title})> _parseSpine(String opf, String opfDir) {
    final manifest = <String, ({String href, String? title})>{};
    for (final m in RegExp(r'<item\b([^>]*)/>', caseSensitive: false, dotAll: true)
        .allMatches(opf)) {
      final attrs = m.group(1)!;
      final id = _attr(attrs, 'id');
      final href = _attr(attrs, 'href');
      if (id != null && href != null) {
        manifest[id] = (href: href, title: _attr(attrs, 'title'));
      }
    }

    final result = <({String path, String? title})>[];
    for (final s in RegExp(r'<itemref\b([^>]*)/>', caseSensitive: false, dotAll: true)
        .allMatches(opf)) {
      final idref = _attr(s.group(1)!, 'idref');
      if (idref == null) continue;
      final item = manifest[idref];
      if (item == null) continue;
      final resolved = p.posix.normalize(
        p.posix.join(opfDir, Uri.decodeFull(item.href)),
      );
      result.add((path: resolved, title: item.title));
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
  ///
  /// 块级元素（p/div/h1-6/li 等）转为段落分隔（\n\n），使正文能按容器宽度自动折行；
  /// 段内原始换行与 <br> 统一压成空格，避免每行按源文件短行硬换行、填不满屏幕。
  String _extractText(String html) {
    var text = html;
    text = text.replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ');
    text = text.replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ');
    // 块级元素 → 段落分隔；<br>/<hr> → 空格（随后随段内换行一起压成空格）
    text = text.replaceAllMapped(
      RegExp(r'</?(?:p|div|section|article|blockquote|h[1-6]|li|tr|br|hr)\b[^>]*>',
          caseSensitive: false),
      (m) => (m.group(0)!.contains('br') || m.group(0)!.contains('hr'))
          ? ' '
          : '\n\n',
    );
    // 其余标签（span/em/b/a/img 等）→ 空格
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = _decodeEntities(text);
    // 归一化空白：
    //  1) 连续换行（段落）→ 占位符
    //  2) 段内换行（源文件换行 / <br>）→ 空格，自动折行填满
    //  3) 多余空格压成单个
    //  4) 占位符还原为 \n\n
    const paraMark = '\x00';
    text = text
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'\n\s*\n+'), paraMark)
        .replaceAll(RegExp(r'[ \t]*\n[ \t]*'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceAll(paraMark, '\n\n');
    return text.trim();
  }

  static const Map<String, String> _namedEntities = {
    'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'",
    'nbsp': ' ', 'copy': '©', 'reg': '®', 'trade': '™',
    'mdash': '—', 'ndash': '–', 'hellip': '…', 'middot': '·',
    'lsquo': '‘', 'rsquo': '’', 'ldquo': '“', 'rdquo': '”',
    'laquo': '«', 'raquo': '»', 'bull': '•', 'deg': '°',
    'times': '×', 'divide': '÷', 'plusmn': '±', 'frac12': '½',
    'euro': '€', 'pound': '£', 'yen': '¥', 'sect': '§',
    'para': '¶', 'dagger': '†', 'Dagger': '‡',
  };

  /// 解码 XML/HTML 实体：十进制、十六进制（&#xHH;）与常见命名实体。
  String _decodeEntities(String text) {
    return text.replaceAllMapped(
      RegExp(r'&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'),
      (m) {
        final body = m.group(1)!;
        if (body.startsWith('#x') || body.startsWith('#X')) {
          return String.fromCharCode(int.parse(body.substring(2), radix: 16));
        }
        if (body.startsWith('#')) {
          return String.fromCharCode(int.parse(body.substring(1)));
        }
        return _namedEntities[body] ?? m.group(0)!;
      },
    );
  }
}
