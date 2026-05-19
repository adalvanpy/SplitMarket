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

  final TextEditingController
      descriptionController =
          TextEditingController();

  final TextEditingController
      valueController =
          TextEditingController();

  final TextEditingController
      payerController =
          TextEditingController();

  final ExpenseService expenseService =
      ExpenseService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      body: SingleChildScrollView(

        child: Column(

          children: [

            // Cabeçalho
            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                16,
                50,
                24,
                40,
              ),

              decoration: const BoxDecoration(

                gradient: LinearGradient(

                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                  colors: [

                    Color(0xFF8E76F7),

                    Color(0xFFB993F9),
                  ],
                ),

                borderRadius:
                    BorderRadius.only(

                  bottomLeft:
                      Radius.circular(40),

                  bottomRight:
                      Radius.circular(40),
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      IconButton(

                        onPressed: () =>
                            Navigator.pop(
                          context,
                        ),

                        icon: const Icon(

                          Icons
                              .arrow_back_ios_new,

                          color: Colors.white,

                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Text(

                        'Nova Despesa',

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 26,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Padding(

                    padding:
                        EdgeInsets.only(
                      left: 12,
                    ),

                    child: Text(

                      'Preencha os detalhes abaixo para registrar um novo gasto.',

                      style: TextStyle(

                        color:
                            Colors.white70,

                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Formulário
            Padding(

              padding:
                  const EdgeInsets.all(24),

              child: Column(

                children: [

                  _buildStyledTextField(

                    context,

                    controller:
                        descriptionController,

                    label: 'Descrição',

                    icon:
                        Icons.description_outlined,
                  ),

                  const SizedBox(height: 20),

                  _buildStyledTextField(

                    context,

                    controller:
                        valueController,

                    label: 'Valor (R\$)',

                    icon:
                        Icons.payments_outlined,

                    keyboardType:
                        TextInputType.number,
                  ),

                  const SizedBox(height: 20),

                  _buildStyledTextField(

                    context,

                    controller:
                        payerController,

                    label: 'Quem pagou?',

                    icon:
                        Icons.person_outline,
                  ),

                  const SizedBox(height: 40),

                  // Botão salvar
                  SizedBox(

                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(

                      style:
                          ElevatedButton
                              .styleFrom(

                        backgroundColor:
                            const Color(
                          0xFF8E76F7,
                        ),

                        foregroundColor:
                            Colors.white,

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                        ),

                        elevation: 2,
                      ),

                      onPressed: () async {

                        if (descriptionController
                                .text
                                .isEmpty ||
                            valueController
                                .text
                                .isEmpty ||
                            payerController
                                .text
                                .isEmpty) {

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(

                            const SnackBar(

                              content: Text(
                                'Preencha todos os campos',
                              ),
                            ),
                          );

                          return;
                        }

                        final expense =
                            ExpenseModel(

                          description:
                              descriptionController
                                  .text,

                          value: double.parse(
                            valueController
                                .text,
                          ),

                          payer:
                              payerController
                                  .text,
                        );

                        await expenseService
                            .insertExpense(
                          expense,
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(

                          const SnackBar(

                            content: Text(
                              'Despesa salva com sucesso!',
                            ),
                          ),
                        );

                        Navigator.pop(
                          context,
                        );
                      },

                      child: const Text(

                        'Salvar Despesa',

                        style: TextStyle(

                          fontSize: 18,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(

        decoration: BoxDecoration(

          color:
              Theme.of(context)
                  .cardColor,

          boxShadow: [

            BoxShadow(

              color:
                  Colors.black.withOpacity(
                0.05,
              ),

              blurRadius: 10,

              offset: const Offset(0, -5),
            ),
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: 0,

          type:
              BottomNavigationBarType.fixed,

          backgroundColor:
              Theme.of(context)
                  .cardColor,

          selectedItemColor:
              const Color(0xFF8E76F7),

          unselectedItemColor:
              Colors.grey,

          showUnselectedLabels: true,

          onTap: (index) {

            final routes = [

              '/add-expense',
              '/expenses',
              '/summary',
              '/settings',
            ];

            if (index == 0) return;

            Navigator.pushNamed(
              context,
              routes[index],
            );
          },

          items: const [

            BottomNavigationBarItem(

              icon: Icon(
                Icons.add_circle_outline,
              ),

              label: 'Adicionar',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.receipt_long_outlined,
              ),

              label: 'Despesas',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.analytics_outlined,
              ),

              label: 'Resumo',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.settings_outlined,
              ),

              label: 'Configurações',
            ),
          ],
        ),
      ),
    );
  }

  // Campo estilizado
  Widget _buildStyledTextField(

    BuildContext context, {

    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    TextInputType keyboardType =
        TextInputType.text,
  }) {

    return Container(

      decoration: BoxDecoration(

        color:
            Theme.of(context).cardColor,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withOpacity(
              0.03,
            ),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboardType,

        style: TextStyle(

          color:
              Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color,
        ),

        decoration: InputDecoration(

          labelText: label,

          labelStyle: const TextStyle(
            color: Colors.grey,
          ),

          prefixIcon: Icon(

            icon,

            color: const Color(
              0xFF8E76F7,
            ),
          ),

          border: InputBorder.none,

          contentPadding:
              const EdgeInsets.symmetric(

            horizontal: 20,

            vertical: 16,
          ),
        ),
      ),
    );
  }
}