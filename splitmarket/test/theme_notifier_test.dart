import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:splitmarket/core/themes/theme_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeNotifier Test', () {
    test('deve iniciar no tema claro', () async {
      final notifier = ThemeNotifier();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(notifier.isDarkMode, false);
    });

    test('deve alternar o tema', () async {
      final notifier = ThemeNotifier();

      await Future.delayed(const Duration(milliseconds: 200));

      final initialTheme = notifier.isDarkMode;

      await notifier.toggleTheme();

      expect(notifier.isDarkMode, !initialTheme);
    });
  });
}