import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/book.dart';
import '../../../../core/models/reader_mode.dart';
import '../../../../core/services/settings_service.dart';
import '../controllers/reader_bloc.dart';
import '../../domain/usecases/load_book.dart';
import '../controllers/reader_ui_cubit.dart';
import '../widgets/paged_reader.dart';
import '../widgets/scroll_reader.dart';

/// 阅读页：Bloc 加载文档，Cubit 管理 UI（模式/字号）。
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => ReaderBloc(loadBook: ctx.read<LoadBook>())
            ..add(ReaderLoadRequested(book)),
        ),
        BlocProvider(
          create: (_) =>
              ReaderUiCubit(settings: context.read<SettingsService>()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ReaderBloc, ReaderState>(
            builder: (context, state) =>
                Text(state is ReaderLoaded ? state.doc.book.title : book.title),
          ),
          actions: [
            BlocBuilder<ReaderUiCubit, ReaderUiState>(
              builder: (context, ui) => IconButton(
                icon: Icon(ui.mode == ReaderMode.scroll
                    ? Icons.view_agenda
                    : Icons.notes),
                tooltip: ui.mode == ReaderMode.scroll ? '切换到分页' : '切换到滚动',
                onPressed: () => context.read<ReaderUiCubit>().toggleMode(),
              ),
            ),
            BlocBuilder<ReaderUiCubit, ReaderUiState>(
              builder: (context, ui) => IconButton(
                icon: const Icon(Icons.text_decrease),
                tooltip: '减小字号',
                onPressed: () => context.read<ReaderUiCubit>().decreaseFont(),
              ),
            ),
            BlocBuilder<ReaderUiCubit, ReaderUiState>(
              builder: (context, ui) => IconButton(
                icon: const Icon(Icons.text_increase),
                tooltip: '增大字号',
                onPressed: () => context.read<ReaderUiCubit>().increaseFont(),
              ),
            ),
          ],
        ),
        body: BlocBuilder<ReaderBloc, ReaderState>(
          builder: (context, state) {
            if (state is ReaderLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ReaderFailure) {
              return Center(child: Text('加载失败：${state.message}'));
            }
            if (state is! ReaderLoaded) {
              return const SizedBox.shrink();
            }
            return BlocBuilder<ReaderUiCubit, ReaderUiState>(
              builder: (context, ui) => ui.mode == ReaderMode.scroll
                  ? ScrollReader(
                      chapters: state.doc.chapters,
                      fontSize: ui.fontSize,
                    )
                  : PagedReader(
                      chapters: state.doc.chapters,
                      fontSize: ui.fontSize,
                    ),
            );
          },
        ),
      ),
    );
  }
}
