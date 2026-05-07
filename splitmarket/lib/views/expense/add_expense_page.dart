import 'package:flutter/material.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
      ),
      body: const Center(
        child: Text('Add Expense Page'),
      ),
    );
  }
}