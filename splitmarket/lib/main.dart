import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/services/preferences_service.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/theme_notifier.dart';

import 'features/auth/views/login_page.dart';
import 'features/auth/views/register_page.dart';
import 'features/home/views/home_page.dart';
import 'features/groups/views/group_page.dart';
import 'features/expenses/views/expense_page.dart';
import 'features/expenses/views/add_expense_page.dart';
import 'features/summary/views/summary_page.dart';
import 'features/notifications/viewmodels/notification_provider.dart';
import 'features/notifications/views/notifications_page.dart';
import 'features/settings/views/settings_page.dart';
import 'features/profile/views/profile_page.dart';

// Repositories
import 'data/repositories/group_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DESKTOP ONLY - Configuração do SQLite para desktop
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const SplitMarketApp(),
    ),
  );
}

class SplitMarketApp extends StatefulWidget {
  const SplitMarketApp({super.key});

  @override
  State<SplitMarketApp> createState() => _SplitMarketAppState();
}

class _SplitMarketAppState extends State<SplitMarketApp> {
  bool isLogged = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    try {
      final logged = await PreferencesService.getLogin();
      setState(() {
        isLogged = logged;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao verificar login: $e');
      setState(() {
        isLogged = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SplitMarket',
          
          // ============================================================
          // ✅ SUPORTE A PORTUGUÊS (TalkBack em PT-BR)
          // ============================================================
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate, // ✅ Substitui GlobalWidgetsLocalizations
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          
          // ============================================================
          // ✅ TEMAS
          // ============================================================
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.currentTheme,
          
          // ============================================================
          // ✅ TELA INICIAL
          // ============================================================
          home: isLogged ? const HomePage() : const LoginPage(),
          
          // ============================================================
          // ✅ ROTAS
          // ============================================================
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
            '/group': (context) => const GroupPage(),
            '/expenses': (context) => const ExpensePage(),
            '/add-expense': (context) => const AddExpensePage(),
            '/summary': (context) => const SummaryPage(),
            '/settings': (context) => const SettingsPage(),
            '/notifications': (context) => const NotificationsPage(),
            '/profile': (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}