import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() =>
      _ExpensePageState();
}

class _ExpensePageState
    extends State<ExpensePage> {

  final ExpenseService expenseService =
      ExpenseService();

  List<ExpenseModel> expenses = [];

  @override
  void initState() {
    super.initState();

    loadExpenses();
  }

  Future<void> loadExpenses() async {

    final data =
        await expenseService.getExpenses();

    setState(() {
      expenses = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Despesas'),
      ),

      body: expenses.isEmpty

          ? const Center(
              child: Text(
                'Nenhuma despesa cadastrada',
              ),
            )

          : ListView.builder(

              itemCount: expenses.length,

              itemBuilder: (context, index) {

                final expense =
                    expenses[index];

                return Card(

                  margin: const EdgeInsets.all(12),

                  child: ListTile(

                    title: Text(
                      expense.description,
                    ),

                    subtitle: Text(
                      'Pago por: ${expense.payer}',
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R\$ ${expense.value.toStringAsFixed(2)}',
                        ),
                        IconButton(
                          onPressed: () async {
                            await expenseService.deleteExpense(
                              expense.id!,
                            );
                            loadExpenses();
                          },
                          icon: const Icon(
                            Icons.delete,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}