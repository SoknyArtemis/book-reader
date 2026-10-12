import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loader/book_loader_registry.dart';
import 'loader/epub_book_loader.dart';
import 'loader/txt_book_loader.dart';
import 'services/library_service.dart';
import 'services/settings_service.dart';

/// 设置服务。在 main() 中通过 override 注入已初始化的实例（同步可用）。
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => throw StateError('settingsServiceProvider 必须在 main() 中 override'),
);

/// 加载器注册表，注册所有支持的格式实现。
final bookLoaderRegistryProvider = Provider<BookLoaderRegistry>(
  (ref) => const BookLoaderRegistry([
    TxtBookLoader(),
    EpubBookLoader(),
  ]),
);

/// 书架服务。
final libraryServiceProvider = Provider<LibraryService>((ref) => const LibraryService());
