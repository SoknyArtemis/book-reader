import 'package:flutter/material.dart';

/// Material 3 主题。支持系统动态取色（Material You）：
/// 在 Android 12+ 上从壁纸提取配色，否则回退到种子色。
class AppTheme {
  static ThemeData light(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ?? ColorScheme.fromSeed(seedColor: Colors.teal);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark(ColorScheme? dynamicScheme) {
    final base = dynamicScheme ?? ColorScheme.fromSeed(seedColor: Colors.teal);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      brightness: Brightness.dark,
    );
  }
}
