import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router.dart';
import 'theme.dart';
import '../core/loader/book_loader_registry.dart';
import '../core/services/settings_service.dart';
import '../features/library/data/datasources/library_datasource.dart';
import '../features/library/data/repositories/library_repository_impl.dart';
import '../features/library/domain/repositories/library_repository.dart';
import '../features/library/domain/usecases/get_library_books.dart';
import '../features/library/domain/usecases/import_books.dart';
import '../features/reader/data/repositories/book_repository_impl.dart';
import '../features/reader/domain/repositories/book_repository.dart';
import '../features/reader/domain/usecases/load_book.dart';

/// 应用根：Material3 + 动态取色 + go_router，并通过 RepositoryProvider 提供
/// 服务、仓库与用例（即 DI 装配点）。
class App extends StatelessWidget {
  const App({
    super.key,
    required this.settings,
    required this.bookLoaderRegistry,
  });
  final SettingsService settings;
  final BookLoaderRegistry bookLoaderRegistry;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SettingsService>.value(value: settings),
            RepositoryProvider<BookLoaderRegistry>.value(value: bookLoaderRegistry),
            RepositoryProvider<LibraryRepository>(
              create: (_) =>
                  const LibraryRepositoryImpl(FileSystemLibraryDataSource()),
            ),
            RepositoryProvider<BookRepository>(
              create: (ctx) =>
                  BookRepositoryImpl(ctx.read<BookLoaderRegistry>()),
            ),
            RepositoryProvider<GetLibraryBooks>(
              create: (ctx) => GetLibraryBooks(ctx.read<LibraryRepository>()),
            ),
            RepositoryProvider<ImportBooks>(
              create: (ctx) => ImportBooks(ctx.read<SettingsService>()),
            ),
            RepositoryProvider<LoadBook>(
              create: (ctx) => LoadBook(ctx.read<BookRepository>()),
            ),
          ],
          child: MaterialApp.router(
            title: 'book_reader',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(lightDynamic),
            darkTheme: buildAppTheme(darkDynamic, isDark: true),
            themeMode: ThemeMode.system,
            routerConfig: router,
          ),
        );
      },
    );
  }
}
