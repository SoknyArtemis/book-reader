import '../models/book.dart';

/// 书籍加载器抽象。每种格式实现此接口，
/// 阅读器通过 [BookLoaderRegistry] 按格式获取对应实现，无需关心具体格式。
abstract class BookLoader {
  /// 是否支持该格式。
  bool supports(BookFormat format);

  /// 将一本书加载为统一的 [BookDocument]。
  Future<BookDocument> load(Book book);
}
