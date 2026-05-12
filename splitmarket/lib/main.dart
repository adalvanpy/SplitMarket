import 'package:flutter/material.dart';
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