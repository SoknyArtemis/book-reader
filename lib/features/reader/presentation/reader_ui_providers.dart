import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/services/settings_service.dart';

/// 阅读翻页模式（从设置初始化）。
final readerModeProvider = StateProvider<ReaderMode>(
  (ref) => ref.read(settingsServiceProvider).readerMode,
);

/// 阅读字号（从设置初始化）。
final readerFontSizeProvider = StateProvider<double>(
  (ref) => ref.read(settingsServiceProvider).fontSize,
);
