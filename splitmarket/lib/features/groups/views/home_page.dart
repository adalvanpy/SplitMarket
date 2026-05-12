import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('SplitMarket'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            const Text(
              'Bem-vinda ao SplitMarket!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(

              onPressed: () {

                Navigator.pushNamed(
                  context,
                  '/add-expense',
                );
              },

              child: const Text(
                'Adicionar Despesa',
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(

              onPressed: () {

                Navigator.pushNamed(
                  context,
                  '/expenses',
                );
              },

              child: const Text(
                'Ver Despesas',
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(

              onPressed: () {

                Navigator.pushNamed(
                  context,
                  '/summary',
                );
              },

              child: const Text(
                'Resumo Financeiro',
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(

              onPressed: () {

                Navigator.pushNamed(
                  context,
                  '/settings',
                );
              },

              child: const Text(
                'Configurações',
              ),
            ),
          ],
        ),
      ),
    );
  }
}