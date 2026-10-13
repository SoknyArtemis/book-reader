import '../../../../core/models/book.dart';

/// 阅读仓库接口：按书籍加载为统一文档（domain 层）。
abstract class BookRepository {
  Future<BookDocument> loadBook(Book book);
}
