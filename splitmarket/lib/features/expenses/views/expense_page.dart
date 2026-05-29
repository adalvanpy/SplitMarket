import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../shared/widgets/custom_buttom_navbar.dart';

import '../../../data/models/expense_model.dart';

import '../../../data/repositories/expense_repository.dart';

class ExpensePage extends StatefulWidget {

  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() =>
      _ExpensePageState();
}

class _ExpensePageState
    extends State<ExpensePage> {

  @override
  void initState() {

    super.initState();

    Future.microtask(() {

      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).carregarDespesas();
    });
  }

  double totalExpenses(
    List<ExpenseModel> expenses,
  ) {

    double total = 0;

    for (var expense in expenses) {
      total += expense.value;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      body: Column(

        children: [

          // Cabeçalho
          Container(

            width: double.infinity,

            padding: const EdgeInsets.fromLTRB(
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

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    IconButton(

                      onPressed: () =>
                          Navigator.pop(context),

                      icon: const Icon(

                        Icons.arrow_back_ios_new,

                        color: Colors.white,

                        size: 24,
                      ),
                    ),

                    const Text(

                      'Suas Despesas',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 24,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    IconButton(

                      onPressed: () async {

                        await Navigator.pushNamed(
                          context,
                          '/add-expense',
                        );

                        Provider.of<ExpenseProvider>(
                          context,
                          listen: false,
                        ).carregarDespesas();
                      },

                      icon: const Icon(

                        Icons.add_circle,

                        color: Colors.white,

                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Padding(

                  padding:
                      const EdgeInsets.only(
                    left: 12,
                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Total acumulado',

                        style: TextStyle(

                          color:
                              Colors.white
                                  .withOpacity(
                            0.7,
                          ),

                          fontSize: 16,
                        ),
                      ),

                      Consumer<ExpenseProvider>(

                        builder: (
                          context,
                          provider,
                          child,
                        ) {

                          return Text(

                            'R\$ ${totalExpenses(provider.despesas).toStringAsFixed(2)}',

                            style: const TextStyle(

                              color: Colors.white,

                              fontSize: 36,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(

            child: Consumer<ExpenseProvider>(

              builder: (
                context,
                provider,
                child,
              ) {

                if (provider.carregando) {

                  return const Center(

                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (provider.despesas.isEmpty) {

                  return _buildEmptyState();
                }

                return ListView.builder(

                  padding:
                      const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                  ),

                  itemCount:
                      provider.despesas.length,

                  itemBuilder:
                      (context, index) {

                    final expense =
                        provider
                            .despesas[index];

                    return _buildExpenseCard(
                      context,
                      expense,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation reutilizável
      bottomNavigationBar:
          const CustomBottomNavbar(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildEmptyState() {

    return Center(

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(

            Icons.receipt_long_outlined,

            size: 80,

            color: Colors.grey[300],
          ),

          const SizedBox(height: 16),

          const Text(

            'Nenhuma despesa cadastrada',

            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel expense,
  ) {

    return Container(

      margin: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ),

      decoration: BoxDecoration(

        color:
            Theme.of(context).cardColor,

        borderRadius:
            BorderRadius.circular(20),

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

      child: ListTile(

        contentPadding:
            const EdgeInsets.all(16),

        leading: Container(

          padding:
              const EdgeInsets.all(10),

          decoration: BoxDecoration(

            color: const Color(
              0xFFF0EDFF,
            ),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: const Icon(

            Icons.attach_money,

            color: Color(0xFF8E76F7),
          ),
        ),

        title: Text(

          expense.description,

          style: TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 16,

            color:
                Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color,
          ),
        ),

        subtitle: Text(

          'Pago por: ${expense.payer}',

          style: TextStyle(

            color: Colors.grey[700],

            fontSize: 14,
          ),
        ),

        trailing: Row(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Text(

              'R\$ ${expense.value.toStringAsFixed(2)}',

              style: const TextStyle(

                fontWeight:
                    FontWeight.bold,

                color: Color(0xFFE57373),

                fontSize: 16,
              ),
            ),

            IconButton(

              icon: const Icon(

                Icons.delete_outline,

                color: Colors.grey,
              ),

              onPressed: () async {

                await Provider.of<
                    ExpenseProvider>(
                  context,
                  listen: false,
                ).deletarDespesa(
                  expense.id!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}