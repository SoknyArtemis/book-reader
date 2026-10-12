import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'theme.dart';

/// 应用根组件。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return DynamicColorBuilder(
      builder: (lightScheme, darkScheme) {
        return MaterialApp.router(
          title: '书阅',
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
