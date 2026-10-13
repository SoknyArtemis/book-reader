import '../models/book.dart';
import 'book_loader.dart';

/// 加载器注册表。按格式查找对应 [BookLoader]。
///
/// 设计约定：核心层只内置 TXT（底层基础，允许与核心耦合）；
/// 其它格式（EPUB / 未来的 PDF 等）置于 [lib/formats/<format>/]，
/// 仅依赖本契约与领域模型，做到解耦——新增/移除某格式时不改动核心。
/// 只需实现 [BookLoader] 并在此注册即可，阅读器代码无需改动。
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
