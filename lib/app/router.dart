import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/book.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/reader/presentation/reader_screen.dart';

/// 应用路由。书架为根，阅读页通过 extra 接收 [Book] 对象。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final book = state.extra as Book;
          return ReaderScreen(book: book);
        },
      ),
    ],
  );
});
