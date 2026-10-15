import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';
import '../../../../core/services/saf_service.dart';

/// 文件系统数据源：扫描目录（或 SAF tree）与汇总导入项。
class FileSystemLibraryDataSource {
  const FileSystemLibraryDataSource();

  /// 汇总书架：所选外部文件夹（原地读）+ 单独导入的书籍。
  Future<List<Book>> getBooks(String? dir, List<ImportedBook> imported) async {
    final books = <Book>[];
    if (dir != null) {
      books.addAll(await scan(dir));
    }
    for (final it in imported) {
      if (books.any((b) => b.id == it.path)) continue;
      final format = BookFormatX.fromPath(it.name);
      if (format == BookFormat.unknown) continue;
      books.add(Book(
        id: it.path,
        title: p.basenameWithoutExtension(it.name),
        format: format,
        path: it.path,
        sizeBytes: it.size,
        addedAt: DateTime.now(),
      ));
    }
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  /// 扫描文件夹：Android 上 dir 为 SAF tree URI，走 ContentResolver；否则 dart:io。
  Future<List<Book>> scan(String dirPath) async {
    if (dirPath.startsWith('content://')) {
      return _scanTree(dirPath);
    }
    return _scanFs(dirPath);
  }

  Future<List<Book>> _scanFs(String dirPath) async {
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
    return books;
  }

  /// 经 SAF 递归列出 tree 下的书籍（content URI），无需把文件拷进私有目录。
  Future<List<Book>> _scanTree(String treeUri) async {
    final list = await SafService.listTree(treeUri);
    final books = <Book>[];
    for (final item in list) {
      final name = (item['name'] as String?) ?? '';
      final uri = item['uri'] as String?;
      if (uri == null) continue;
      final format = BookFormatX.fromPath(name);
      if (format == BookFormat.unknown) continue;
      books.add(Book(
        id: uri,
        title: p.basenameWithoutExtension(name),
        format: format,
        path: uri,
        sizeBytes: (item['size'] as int?) ?? 0,
        addedAt: DateTime.now(),
      ));
    }
    return books;
  }
}
