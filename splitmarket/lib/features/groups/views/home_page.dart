import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      body: SingleChildScrollView(

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // Header com Degradê
            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                24,
                60,
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

                  const Text(

                    'Bem-vinda ao SplitMarket!',

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 26,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(

                    'Gerencie despesas em grupo de forma simples.',

                    style: TextStyle(

                      color:
                          Colors.white.withOpacity(
                        0.7,
                      ),

                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(

              padding:
                  const EdgeInsets.all(24),

              child: Text(

                'Visão Geral',

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
}