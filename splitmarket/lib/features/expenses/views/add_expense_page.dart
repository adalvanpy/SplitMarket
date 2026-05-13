import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() =>
      _AddExpensePageState();
}

class _AddExpensePageState
    extends State<AddExpensePage> {

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController valueController =
      TextEditingController();

  final TextEditingController payerController =
      TextEditingController();

  final ExpenseService expenseService =
      ExpenseService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            TextField(
              controller: descriptionController,

              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: payerController,

              decoration: const InputDecoration(
                labelText: 'Quem pagou',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: () async {

                  if (
                    descriptionController.text.isEmpty ||
                    valueController.text.isEmpty ||
                    payerController.text.isEmpty
                  ) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(
                        content: Text(
                          'Preencha todos os campos',
                        ),
                      ),
                    );

                    return;
                  }

                  final expense = ExpenseModel(
                    description:
                        descriptionController.text,

                    value: double.parse(
                      valueController.text,
                    ),

                    payer:
                        payerController.text,
                  );

                  await expenseService
                      .insertExpense(expense);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(
                      content: Text(
                        'Despesa salva com sucesso!',
                      ),
                    ),
                  );

                  Navigator.pop(context);
                },

                child: const Text(
                  'Salvar Despesa',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}