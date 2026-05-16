import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {

  static const String loginKey =
      'isLogged';

  static Future<void> saveLogin(
    bool value,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      loginKey,
      value,
    );
  }

  static Future<bool> getLogin() async {

    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          loginKey,
        ) ??
        false;
  }

  static Future<void> logout() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      loginKey,
    );
  }

  static Future<void> saveTheme(
    bool isDark,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'isDarkMode',
      isDark,
    );
  }

  static Future<bool> getTheme() async {

    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          'isDarkMode',
        ) ??
        false;
  }
}