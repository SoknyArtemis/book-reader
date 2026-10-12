import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/book.dart';
import '../../../core/providers.dart';
import '../../../core/services/settings_service.dart';
import '../widgets/paged_reader.dart';
import '../widgets/scroll_reader.dart';
import 'reader_controller.dart';
import 'reader_ui_providers.dart';

/// 阅读页：按滚动/分页模式展示书籍内容，并支持切换模式与字号。
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(readerControllerProvider(book));
    final mode = ref.watch(readerModeProvider);
    final fontSize = ref.watch(readerFontSizeProvider);
    final settings = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: Icon(mode == ReaderMode.scroll ? Icons.view_agenda : Icons.notes),
            tooltip: mode == ReaderMode.scroll ? '切换到分页' : '切换到滚动',
            onPressed: () {
              final next =
                  mode == ReaderMode.scroll ? ReaderMode.page : ReaderMode.scroll;
              ref.read(readerModeProvider.notifier).state = next;
              settings.setReaderMode(next);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: '减小字号',
            onPressed: () => _changeFont(ref, settings, fontSize, -1),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: '增大字号',
            onPressed: () => _changeFont(ref, settings, fontSize, 1),
          ),
        ],
      ),
      body: docAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (doc) => mode == ReaderMode.scroll
            ? ScrollReader(chapters: doc.chapters, fontSize: fontSize)
            : PagedReader(chapters: doc.chapters, fontSize: fontSize),
      ),
    );
  }

  void _changeFont(
    WidgetRef ref,
    SettingsService settings,
    double current,
    double delta,
  ) {
    final next = (current + delta).clamp(12.0, 36.0);
    ref.read(readerFontSizeProvider.notifier).state = next;
    settings.setFontSize(next);
  }
}
