import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../../core/models/book.dart';

/// 文件系统数据源：扫描目录与导入文件。
class FileSystemLibraryDataSource {
  const FileSystemLibraryDataSource();

  Future<List<Book>> scan(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return const [];
    final books = <Book>[];
    await for (final entity in dir.list(recursive: true).handleError(
      (e) {
        // 仅跳过文件系统类错误（如某子目录无权访问）；逻辑层错误应上浮以便排查。
        debugPrint('[library] 跳过无法列举的条目：$e');
      },
      test: (e) => e is FileSystemException,
    )) {
      if (entity is! File) continue;
      final format = BookFormatX.fromPath(entity.path);
      if (format == BookFormat.unknown) continue;
      try {
        final stat = await entity.stat();
        books.add(Book(
          id: entity.path,
          title: p.basenameWithoutExtension(entity.path),
          format: format,
          path: entity.path,
          sizeBytes: stat.size,
          addedAt: stat.modified,
        ));
      } on FileSystemException {
        // 文件在列举后消失或无法访问，跳过。
      }
    }
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

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
