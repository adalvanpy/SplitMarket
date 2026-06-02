// lib/shared/widgets/custom_bottom_navbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/preferences_service.dart';
import '../../features/notifications/viewmodels/notification_provider.dart';

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
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: const Color(0xFF8E76F7),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == currentIndex) return;

          final routes = [
            '/home',        // Dashboard
            '/expenses',    // Despesas
            '/group',       // Grupos
            '/settings',    // Configurações
          ];

          Navigator.pushReplacementNamed(context, routes[index]);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Despesas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: FutureBuilder<String>(
              future: PreferencesService.getUserName(),
              builder: (context, snapshot) {
                final currentUser = snapshot.data ?? 'Usuário';
                return Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final hasPending = notificationProvider.hasPendingFor(currentUser);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.settings_outlined),
                        if (hasPending)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}