import 'package:flutter/material.dart';

import 'views/login/login_page.dart';
import 'views/login/register_page.dart';
import 'views/home/home_page.dart';
import 'views/group/group_page.dart';
import 'views/expense/expense_page.dart';
import 'views/expense/add_expense_page.dart';
import 'views/summary/summary_page.dart';
import 'views/settings/settings_page.dart';

void main() {
  runApp(const SplitMarketApp());
}

class SplitMarketApp extends StatelessWidget {
  const SplitMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SplitMarket',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/group': (context) => const GroupPage(),
        '/expenses': (context) => const ExpensePage(),
        '/add-expense': (context) => const AddExpensePage(),
        '/sumary': (context) => const SummaryPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}