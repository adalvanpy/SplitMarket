import 'package:flutter/material.dart';

import 'views/login/login_page.dart';

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
      home: const LoginPage(),
    );
  }
}