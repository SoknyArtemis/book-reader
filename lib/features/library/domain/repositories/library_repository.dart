import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';

/// 书架仓库接口（domain 层，无实现细节）。
abstract class LibraryRepository {
  /// 汇总书架：所选外部文件夹（原地读）+ 单独导入的书籍。
  Future<List<Book>> getBooks(String? dir, List<ImportedBook> imported);
}
