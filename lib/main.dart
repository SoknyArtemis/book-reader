import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/loader/book_loader_registry.dart';
import 'core/loader/txt_book_loader.dart';
import 'formats/epub/epub_book_loader.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  const bookLoaderRegistry =
      BookLoaderRegistry([TxtBookLoader(), EpubBookLoader()]);
  runApp(App(settings: settings, bookLoaderRegistry: bookLoaderRegistry));
}
