import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {

  const SummaryPage({super.key});

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

          // Conteúdo principal
          Expanded(

            child: Center(

              child: Column(

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Icon(

                    Icons.analytics_outlined,

                    size: 80,

                    color: Theme.of(context)
                        .iconTheme
                        .color,
                  ),

                  const SizedBox(height: 20),

                  Text(

                    'Resumo Financeiro',

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,

                      color: Theme.of(context)

                          .textTheme

                          .bodyLarge

                          ?.color,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(

                    'Em breve você verá gráficos e estatísticas das despesas.',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(

                      fontSize: 16,

                      color: Theme.of(context)

                          .textTheme

                          .bodyMedium

                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

          currentIndex: 2,

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

            if (index == 2) return;

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
}