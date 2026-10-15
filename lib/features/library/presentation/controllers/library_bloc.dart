import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';
import '../../../../core/services/settings_service.dart';
import '../../domain/usecases/get_library_books.dart';
import '../../domain/usecases/import_books.dart';
import 'dart:io';

String _userMessage(Object e) {
  if (e is FileSystemException) {
    return '文件访问失败：${e.message}';
  }
  final s = e.toString();
  if (s.startsWith('BookLoadFailure:')) return s;
  return '操作失败：$s';
}

// ----------------------------- Events -----------------------------
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested();
}

class LibraryDirectoryPicked extends LibraryEvent {
  const LibraryDirectoryPicked(this.dir);
  final String dir;
  @override
  List<Object?> get props => [dir];
}

class LibraryImportRequested extends LibraryEvent {
  const LibraryImportRequested({required this.items});
  final List<ImportedBook> items;
  @override
  List<Object?> get props => [items];
}

class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested();
}

// ----------------------------- States -----------------------------
abstract class LibraryState extends Equatable {
  const LibraryState();
  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  const LibraryLoaded(this.books);
  final List<Book> books;
  @override
  List<Object?> get props => [books];
}

class LibraryFailure extends LibraryState {
  const LibraryFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ----------------------------- Bloc -----------------------------
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({
    required GetLibraryBooks getLibraryBooks,
    required ImportBooks importBooks,
    required SettingsService settings,
  })  : _getLibraryBooks = getLibraryBooks,
        _importBooks = importBooks,
        _settings = settings,
        super(const LibraryInitial()) {
    on<LibraryLoadRequested>(_onLoad);
    on<LibraryDirectoryPicked>(_onDirectoryPicked);
    on<LibraryImportRequested>(_onImport);
    on<LibraryRefreshRequested>(_onRefresh);
  }

  final GetLibraryBooks _getLibraryBooks;
  final ImportBooks _importBooks;
  final SettingsService _settings;

  Future<void> _loadFromDir(String? dir, Emitter<LibraryState> emit) async {
    emit(const LibraryLoading());
    try {
      final books = await _getLibraryBooks(dir, _settings.importedBooks);
      emit(LibraryLoaded(books));
    } catch (e) {
      emit(LibraryFailure(_userMessage(e)));
    }
  }

  Future<void> _onLoad(
    LibraryLoadRequested event,
    Emitter<LibraryState> emit,
  ) =>
      _loadFromDir(_settings.libraryDir, emit);

  Future<void> _onDirectoryPicked(
    LibraryDirectoryPicked event,
    Emitter<LibraryState> emit,
  ) async {
    await _settings.setLibraryDir(event.dir);
    await _loadFromDir(event.dir, emit);
  }

  Future<void> _onImport(
    LibraryImportRequested event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _importBooks(event.items);
      await _loadFromDir(_settings.libraryDir, emit);
    } catch (e) {
      emit(LibraryFailure(_userMessage(e)));
    }
  }

  Future<void> _onRefresh(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) =>
      _loadFromDir(_settings.libraryDir, emit);
}
