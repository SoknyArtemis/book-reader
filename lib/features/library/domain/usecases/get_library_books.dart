import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';
import '../repositories/library_repository.dart';

/// 获取书架书籍用例。
class GetLibraryBooks {
  const GetLibraryBooks(this._repository);
  final LibraryRepository _repository;

  Future<List<Book>> call(String? dir, List<ImportedBook> imported) =>
      _repository.getBooks(dir, imported);
}
