import 'package:flutter/material.dart';

import '../../../widgets/custom_buttom_navbar.dart';

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

      // Bottom Navigation reutilizável
      bottomNavigationBar:
          const CustomBottomNavbar(
        currentIndex: 0,
      ),
    );
  }
}