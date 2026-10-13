import '../../../../core/errors/failures.dart';
import '../../../../core/loader/book_loader_registry.dart';
import '../../../../core/models/book.dart';
import '../../domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._registry);
  final BookLoaderRegistry _registry;

  @override
  Future<BookDocument> loadBook(Book book) async {
    final loader = _registry.forFormat(book.format);
    if (loader == null) {
      throw BookLoadFailure('不支持的格式：${book.format.label}');
    }
    return loader.load(book);
  }
}
