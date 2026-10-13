import '../repositories/library_repository.dart';

/// 导入书籍用例。
class ImportBooks {
  const ImportBooks(this._repository);
  final LibraryRepository _repository;

  Future<void> call(List<String> sourcePaths, String targetDir) =>
      _repository.importFiles(sourcePaths, targetDir);
}
