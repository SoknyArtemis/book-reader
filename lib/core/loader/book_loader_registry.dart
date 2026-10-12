import '../models/book.dart';
import 'book_loader.dart';

/// 加载器注册表。按格式查找对应 [BookLoader]。
/// 新增格式只需实现 [BookLoader] 并注册到这里即可，阅读器代码无需改动。
class BookLoaderRegistry {
  const BookLoaderRegistry(this.loaders);
  final List<BookLoader> loaders;

  BookLoader? forFormat(BookFormat format) {
    for (final loader in loaders) {
      if (loader.supports(format)) return loader;
    }
    return null;
  }
}
