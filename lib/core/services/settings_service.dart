import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/imported_book.dart';
import '../models/reader_mode.dart';

/// 应用设置（持久化于 SharedPreferences）。
/// v1 保存：书架目录、阅读模式、字号。
class SettingsService {
  const SettingsService(this._prefs);
  final SharedPreferences _prefs;

  static const _libraryDirKey = 'library_dir';
  static const _readerModeKey = 'reader_mode';
  static const _fontSizeKey = 'reader_font_size';
  static const _importedKey = 'imported_books';

  String? get libraryDir => _prefs.getString(_libraryDirKey);

  Future<void> setLibraryDir(String value) => _prefs.setString(_libraryDirKey, value);

  /// 通过"导入书籍"单独加入书架的书籍（Android 上为 SAF URI，桌面为真实路径）。
  List<ImportedBook> get importedBooks {
    final raw = _prefs.getString(_importedKey);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ImportedBook.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setImportedBooks(List<ImportedBook> value) => _prefs.setString(
        _importedKey,
        jsonEncode(value.map((e) => e.toJson()).toList()),
      );

  ReaderMode get readerMode {
    final index = _prefs.getInt(_readerModeKey);
    if (index == null || index < 0 || index >= ReaderMode.values.length) {
      return ReaderMode.scroll;
    }
    return ReaderMode.values[index];
  }

  Future<void> setReaderMode(ReaderMode mode) => _prefs.setInt(_readerModeKey, mode.index);

  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 18.0;

  Future<void> setFontSize(double value) => _prefs.setDouble(_fontSizeKey, value);
}
