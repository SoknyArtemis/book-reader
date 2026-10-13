import '../../../../core/models/book.dart';

/// 书架仓库接口（domain 层，无实现细节）。
abstract class LibraryRepository {
  /// 扫描目录，返回所有受支持的书籍。
  Future<List<Book>> getBooks(String dir);

  /// 将源文件导入到目标目录。
  Future<void> importFiles(List<String> sourcePaths, String targetDir);
}
