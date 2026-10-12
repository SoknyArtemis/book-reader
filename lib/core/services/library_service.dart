import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/book.dart';

/// 书架服务。v1 中书架即“目录扫描”：列出目录（含子目录）下所有支持的书籍文件。
/// 后续若要支持进度/书签/自定义排序，可在此之上接入数据库，不影响上层调用。
class LibraryService {
  const LibraryService();

  /// 扫描目录，返回所有受支持的书籍（按标题排序）。
  Future<List<Book>> scan(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return const [];
    final books = <Book>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final format = BookFormatX.fromPath(entity.path);
      if (format == BookFormat.unknown) continue;
      final stat = await entity.stat();
      books.add(Book(
        id: entity.path,
        title: p.basenameWithoutExtension(entity.path),
        format: format,
        path: entity.path,
        sizeBytes: stat.size,
        addedAt: stat.modified,
      ));
    }
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  /// 将源文件复制到目标目录（导入书籍）。
  Future<void> importFiles(List<String> sourcePaths, String targetDir) async {
    final dir = Directory(targetDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    for (final src in sourcePaths) {
      final file = File(src);
      if (!await file.exists()) continue;
      final name = p.basename(src);
      await file.copy(p.join(targetDir, name));
    }
  }
}
