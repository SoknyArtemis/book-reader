import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/providers.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  runApp(
    ProviderScope(
      overrides: [settingsServiceProvider.overrideWithValue(settings)],
      child: const App(),
    ),
  );
}
