import 'package:flutter/material.dart';

import '../../../widgets/custom_buttom_navbar.dart';

import '../models/summary_model.dart';
import '../viewmodels/summary_viewmodel.dart';
import '../widgets/summary_card.dart';

 main
class SummaryPage extends StatefulWidget {

  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() =>
      _SummaryPageState();
}

class _SummaryPageState
    extends State<SummaryPage> {

  final SummaryViewModel
      _summaryViewModel =
          SummaryViewModel();

  SummaryModel? summary;

  bool isLoading = true;

  @override
  void initState() {

    super.initState();

    loadSummary();
  }

  Future<void> loadSummary() async {

    final data =
        await _summaryViewModel
            .getSummary();

    setState(() {

      summary = data;

      isLoading = false;
    });
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

                      'Resumo',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 26,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(

            child: isLoading
 refactor/custom-bottom-navbar

                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )

                : Padding(



                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )

                : Padding(

 main
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
 refactor/custom-bottom-navbar

                    child: Column(

                      children: [

                        SummaryCard(

                          title:
                              'Total de Gastos',

                          value:
                              'R\$ ${summary!.totalExpenses.toStringAsFixed(2)}',

                          icon:
                              Icons.attach_money,
                        ),

                        SummaryCard(

                          title:
                              'Quantidade de Despesas',

                          value:
                              '${summary!.totalItems}',

                          icon:
                              Icons.receipt_long,
                        ),

                        SummaryCard(

                          title:
                              'Média por Despesa',

                          value:
                              'R\$ ${summary!.averageExpense.toStringAsFixed(2)}',


                    child: Column(

                      children: [

                        SummaryCard(

                          title:
                              'Total de Gastos',

                          value:
                              'R\$ ${summary!.totalExpenses.toStringAsFixed(2)}',

                          icon:
                              Icons.attach_money,
                        ),

                        SummaryCard(

                          title:
                              'Quantidade de Despesas',

                          value:
                              '${summary!.totalItems}',

                          icon:
                              Icons.receipt_long,
                        ),

                        SummaryCard(

                          title:
                              'Média por Despesa',

                          value:
                              'R\$ ${summary!.averageExpense.toStringAsFixed(2)}',

                          icon:
                              Icons.analytics,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      bottomNavigationBar:
          const CustomBottomNavbar(
        currentIndex: 2,
      ),
    );
  }
}