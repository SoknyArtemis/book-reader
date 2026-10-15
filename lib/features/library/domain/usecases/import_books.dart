import '../../../../core/models/imported_book.dart';
import '../../../../core/services/settings_service.dart';

/// 导入书籍用例：把挑选的书籍（含 SAF URI）合并持久化到设置中，
/// 书架加载时再与所选文件夹一起汇总展示（原地读取，不拷贝文件）。
class ImportBooks {
  const ImportBooks(this._settings);
  final SettingsService _settings;

  Future<void> call(List<ImportedBook> items) async {
    final merged = [..._settings.importedBooks];
    for (final it in items) {
      if (!merged.any((m) => m.path == it.path)) merged.add(it);
    }
    await _settings.setImportedBooks(merged);
  }
}
