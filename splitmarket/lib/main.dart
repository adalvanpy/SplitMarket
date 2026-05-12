import 'package:flutter/material.dart';

import 'core/services/preferences_service.dart';

import 'features/auth/views/login_page.dart';
import 'features/auth/views/register_page.dart';

import 'features/groups/views/home_page.dart';
import 'features/groups/views/group_page.dart';

import 'features/expenses/views/expense_page.dart';
import 'features/expenses/views/add_expense_page.dart';

import 'features/summary/views/summary_page.dart';

import 'features/settings/views/settings_page.dart';

void main() {
  runApp(const SplitMarketApp());
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
    final logged = await PreferencesService.getLogin();

    setState(() {
      isLogged = logged;
      isLoading = false;
    });
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SplitMarket',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),

      home: isLogged
          ? const HomePage()
          : const LoginPage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/group': (context) => const GroupPage(),
        '/expenses': (context) => const ExpensePage(),
        '/add-expense': (context) => const AddExpensePage(),
        '/summary': (context) => const SummaryPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}