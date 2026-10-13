import '../../../../core/models/book.dart';
import '../repositories/book_repository.dart';

/// 加载书籍用例。
class LoadBook {
  const LoadBook(this._repository);
  final BookRepository _repository;

  Future<BookDocument> call(Book book) => _repository.loadBook(book);
}
