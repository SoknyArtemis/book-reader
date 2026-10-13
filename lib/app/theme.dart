import 'package:flutter/material.dart';

/// 构建 Material3 主题；优先使用系统动态取色（dynamic_color 传入的 scheme），
/// 否则回退到固定种子色。
ThemeData buildAppTheme(ColorScheme? dynamicScheme, {bool isDark = false}) {
  final ColorScheme scheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: isDark ? Brightness.dark : Brightness.light,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
