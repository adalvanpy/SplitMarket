import 'package:flutter/material.dart';

class CustomBottomNavbar extends StatelessWidget {

  final int currentIndex;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

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

        currentIndex: currentIndex,

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

          if (index == currentIndex) {
            return;
          }

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
    );
  }
}