import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/book.dart';
import '../../../core/providers.dart';
import '../../../core/services/library_service.dart';
import '../../../core/services/settings_service.dart';

/// 书架状态管理：加载列表、设置书架目录、导入书籍。
final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, List<Book>>(LibraryController.new);

class LibraryController extends AsyncNotifier<List<Book>> {
  LibraryService get _library => ref.read(libraryServiceProvider);
  SettingsService get _settings => ref.read(settingsServiceProvider);

  @override
  Future<List<Book>> build() async {
    final dir = _settings.libraryDir;
    if (dir == null) return const [];
    return _library.scan(dir);
  }

  /// 设置书架目录并重新扫描。
  Future<void> setLibraryDirectory(String dir) async {
    await _settings.setLibraryDir(dir);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _library.scan(dir));
  }

  /// 将文件导入到目标目录并刷新书架。
  Future<void> importInto(String dir, List<String> paths) async {
    await _library.importFiles(paths, dir);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _library.scan(dir));
  }

  Future<void> refresh() async {
    final dir = _settings.libraryDir;
    if (dir == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _library.scan(dir));
  }
}
