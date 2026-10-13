import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/reader_mode.dart';
import '../../../../core/services/settings_service.dart';

/// 阅读器 UI 状态：翻页模式与字号，变更即持久化到 SettingsService。
class ReaderUiState extends Equatable {
  const ReaderUiState({required this.mode, required this.fontSize});
  final ReaderMode mode;
  final double fontSize;

  ReaderUiState copyWith({ReaderMode? mode, double? fontSize}) => ReaderUiState(
        mode: mode ?? this.mode,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  List<Object?> get props => [mode, fontSize];
}

class ReaderUiCubit extends Cubit<ReaderUiState> {
  ReaderUiCubit({required SettingsService settings})
      : _settings = settings,
        super(ReaderUiState(
          mode: settings.readerMode,
          fontSize: settings.fontSize,
        ));
  final SettingsService _settings;

  Future<void> toggleMode() async {
    final next = state.mode == ReaderMode.scroll
        ? ReaderMode.page
        : ReaderMode.scroll;
    await _settings.setReaderMode(next);
    emit(state.copyWith(mode: next));
  }

  Future<void> increaseFont() async {
    final next = (state.fontSize + 1).clamp(12.0, 36.0);
    await _settings.setFontSize(next);
    emit(state.copyWith(fontSize: next));
  }

  Future<void> decreaseFont() async {
    final next = (state.fontSize - 1).clamp(12.0, 36.0);
    await _settings.setFontSize(next);
    emit(state.copyWith(fontSize: next));
  }
}
