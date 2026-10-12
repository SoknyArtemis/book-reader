import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../../core/models/book.dart';
import '../../../core/providers.dart';

/// 阅读器控制器：根据书籍加载对应的 [BookDocument]。
/// 通过 Family 按 [Book] 区分状态。
final readerControllerProvider =
    AsyncNotifierProvider.family<ReaderController, BookDocument, Book>(
  ReaderController.new,
);

class ReaderController extends FamilyAsyncNotifier<BookDocument, Book> {
  @override
  Future<BookDocument> build(Book book) async {
    final registry = ref.read(bookLoaderRegistryProvider);
    final loader = registry.forFormat(book.format);
    if (loader == null) {
      throw BookLoadFailure('不支持的格式：${book.format.label}');
    }
    return loader.load(book);
  }
}
