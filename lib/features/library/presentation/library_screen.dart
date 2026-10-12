import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/providers.dart';
import 'book_list_item.dart';
import 'library_controller.dart';

/// 书架页：展示书籍、选择书架目录、导入书籍。
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(libraryControllerProvider);
    final settings = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.read(libraryControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
        data: (books) {
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
                    onPressed: () => _pickDir(ref),
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
            onPressed: () => _import(ref, settings.libraryDir),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'dir',
            tooltip: '选择书架目录',
            child: const Icon(Icons.folder_open),
            onPressed: () => _pickDir(ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDir(WidgetRef ref) async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      await ref.read(libraryControllerProvider.notifier).setLibraryDirectory(dir);
    }
  }

  Future<void> _import(WidgetRef ref, String? libraryDir) async {
    String dir = libraryDir ??
        '${(await getApplicationDocumentsDirectory()).path}/books';
    if (libraryDir == null) {
      await ref.read(libraryControllerProvider.notifier).setLibraryDirectory(dir);
    }
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      if (paths.isNotEmpty) {
        await ref.read(libraryControllerProvider.notifier).importInto(dir, paths);
      }
    }
  }
}
