import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/models/book.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/reader/presentation/screens/reader_screen.dart';

/// 全局路由表：书架根 + 阅读页（通过 extra 传递 Book）。
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/reader',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Book) {
          return ReaderScreen(book: extra);
        }
        // 深链/刷新等场景 extra 可能丢失，回书架避免崩溃。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    ),
  ],
);
