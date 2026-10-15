import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/book.dart';
import '../../../../core/models/imported_book.dart';
import '../../../../core/services/saf_service.dart';
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
                  onPressed: () => _import(context),
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
    if (Platform.isAndroid) {
      // Android 11+ 作用域存储：走 SAF 选目录并持久化授权，原地读取。
      final uri = await SafService.pickLibraryTree();
      if (uri != null) bloc.add(LibraryDirectoryPicked(uri));
    } else {
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir != null) bloc.add(LibraryDirectoryPicked(dir));
    }
  }

  Future<void> _import(BuildContext context) async {
    final bloc = context.read<LibraryBloc>();
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      final items = <ImportedBook>[];
      for (final f in result.files) {
        if (f.path == null || f.name.isEmpty) continue;
        if (Platform.isAndroid) {
          // 持久化单文件读取授权，便于下次启动后仍能原地读取。
          await SafService.persistUriPermission(f.path!);
        }
        items.add(ImportedBook(path: f.path!, name: f.name, size: f.size));
      }
      if (items.isNotEmpty) {
        bloc.add(LibraryImportRequested(items: items));
      }
    }
  }
}
