import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/models/book.dart';
import '../../../../core/services/settings_service.dart';
import '../controllers/library_bloc.dart';
import '../widgets/book_list_item.dart';
import '../../domain/usecases/get_library_books.dart';
import '../../domain/usecases/import_books.dart';

/// 书架页：展示书籍、选择书架目录、导入书籍（Bloc 驱动）。
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsService>();
    return BlocProvider(
      create: (ctx) => LibraryBloc(
        getLibraryBooks: ctx.read<GetLibraryBooks>(),
        importBooks: ctx.read<ImportBooks>(),
        settings: ctx.read<SettingsService>(),
      )..add(const LibraryLoadRequested()),
      // 用 Builder 让子组件拿到位于 BlocProvider 之下的 context。
      child: Builder(
        builder: (context) {
          final bloc = context.read<LibraryBloc>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('书架'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: () => bloc.add(const LibraryRefreshRequested()),
                ),
              ],
            ),
            body: BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, state) {
                if (state is LibraryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is LibraryFailure) {
                  return Center(child: Text('出错了：${state.message}'));
                }
                final books = state is LibraryLoaded ? state.books : <Book>[];
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('书架是空的'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('选择书架目录'),
                          onPressed: () => _pickDir(context),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => BookListItem(book: books[i]),
                );
              },
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'import',
                  tooltip: '导入书籍',
                  child: const Icon(Icons.file_upload),
                  onPressed: () => _import(context, settings.libraryDir),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'dir',
                  tooltip: '选择书架目录',
                  child: const Icon(Icons.folder_open),
                  onPressed: () => _pickDir(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDir(BuildContext context) async {
    final bloc = context.read<LibraryBloc>();
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      bloc.add(LibraryDirectoryPicked(dir));
    }
  }

  Future<void> _import(BuildContext context, String? libraryDir) async {
    final bloc = context.read<LibraryBloc>();
    final dir = libraryDir ??
        '${(await getApplicationDocumentsDirectory()).path}/books';
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      if (paths.isNotEmpty) {
        bloc.add(LibraryImportRequested(paths: paths, targetDir: dir));
      }
    }
  }
}
