import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/book.dart';
import '../../domain/usecases/load_book.dart';

// ----------------------------- Events -----------------------------
abstract class ReaderEvent extends Equatable {
  const ReaderEvent();
  @override
  List<Object?> get props => [];
}

class ReaderLoadRequested extends ReaderEvent {
  const ReaderLoadRequested(this.book);
  final Book book;
  @override
  List<Object?> get props => [book];
}

// ----------------------------- States -----------------------------
abstract class ReaderState extends Equatable {
  const ReaderState();
  @override
  List<Object?> get props => [];
}

class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

class ReaderLoaded extends ReaderState {
  const ReaderLoaded(this.doc);
  final BookDocument doc;
  @override
  List<Object?> get props => [doc];
}

class ReaderFailure extends ReaderState {
  const ReaderFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ----------------------------- Bloc -----------------------------
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ReaderBloc({required LoadBook loadBook})
      : _loadBook = loadBook,
        super(const ReaderInitial()) {
    on<ReaderLoadRequested>(_onLoad);
  }

  final LoadBook _loadBook;

  Future<void> _onLoad(
    ReaderLoadRequested event,
    Emitter<ReaderState> emit,
  ) async {
    emit(const ReaderLoading());
    try {
      final doc = await _loadBook(event.book);
      emit(ReaderLoaded(doc));
    } on BookLoadFailure catch (e) {
      emit(ReaderFailure(e.message));
    } catch (e) {
      emit(ReaderFailure(e.toString()));
    }
  }
}
