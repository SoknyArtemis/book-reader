import '../../../../core/models/book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._dataSource);
  final FileSystemLibraryDataSource _dataSource;

  @override
  Future<List<Book>> getBooks(String dir) => _dataSource.scan(dir);

  @override
  Future<void> importFiles(List<String> sourcePaths, String targetDir) =>
      _dataSource.importFiles(sourcePaths, targetDir);
}
