import 'dart:io';
import '../errors/failures.dart';
import '../models/book.dart';
import 'book_loader.dart';

/// TXT 加载器。作为最底层的格式实现，直接整篇读入作为单章。
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
    final text = await file.readAsString();
    final content = text.trim();
    final chapter = BookChapter(
      id: '${book.id}#0',
      title: book.title,
      content: content.isEmpty ? '（空文件）' : content,
    );
    return BookDocument(book: book, chapters: [chapter]);
  }
}
