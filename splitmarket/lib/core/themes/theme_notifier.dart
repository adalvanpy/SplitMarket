import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class ThemeNotifier extends ChangeNotifier {

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get currentTheme {

    return _isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  ThemeNotifier() {

    loadTheme();
  }

  Future<void> loadTheme() async {

    _isDarkMode =
        await PreferencesService.getTheme();

    notifyListeners();
  }

  Future<void> toggleTheme() async {

    _isDarkMode = !_isDarkMode;

    await PreferencesService.saveTheme(
      _isDarkMode,
    );

    notifyListeners();
  }
}