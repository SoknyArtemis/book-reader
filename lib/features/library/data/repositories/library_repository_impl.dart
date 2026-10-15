import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._dataSource);
  final FileSystemLibraryDataSource _dataSource;

  @override
  Future<List<Book>> getBooks(String? dir, List<ImportedBook> imported) =>
      _dataSource.getBooks(dir, imported);
}
