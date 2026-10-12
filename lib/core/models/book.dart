import 'package:equatable/equatable.dart';

/// 支持的电子书格式。后续新增格式（PDF 等）在此枚举扩展。
enum BookFormat { txt, epub, unknown }

extension BookFormatX on BookFormat {
  /// 根据文件路径推断格式。
  static BookFormat fromPath(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'txt':
        return BookFormat.txt;
      case 'epub':
        return BookFormat.epub;
      default:
        return BookFormat.unknown;
    }
  }

  String get label => switch (this) {
        BookFormat.txt => 'TXT',
        BookFormat.epub => 'EPUB',
        BookFormat.unknown => '未知',
      };
}

/// 书架中的一本书。id 使用绝对路径，保证重新扫描时稳定不重复。
class Book extends Equatable {
  const Book({
    required this.id,
    required this.title,
    required this.format,
    required this.path,
    this.author,
    this.sizeBytes,
    this.addedAt,
  });

  final String id;
  final String title;
  final String? author;
  final BookFormat format;
  final String path;
  final int? sizeBytes;
  final DateTime? addedAt;

  Book copyWith({
    String? title,
    String? author,
    int? sizeBytes,
  }) =>
      Book(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        format: format,
        path: path,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        addedAt: addedAt,
      );

  @override
  List<Object?> get props => [id, title, author, format, path, sizeBytes, addedAt];
}

/// 一本书的某一章。v1 中 content 为纯文本（EPUB 已抽取文本），
/// 后续富文本渲染可在此扩展为结构化节点。
class BookChapter extends Equatable {
  const BookChapter({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;

  @override
  List<Object?> get props => [id, title, content];
}

/// 解析后的完整书籍文档，是阅读器消费的统一模型。
class BookDocument extends Equatable {
  const BookDocument({
    required this.book,
    required this.chapters,
  });

  final Book book;
  final List<BookChapter> chapters;

  @override
  List<Object?> get props => [book, chapters];
}
