/// lib/shared/widgets/custom_buttom_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Semantics(
      container: true,
      label: 'Barra de navegação inferior',
      child: Container(
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
          selectedLabelStyle: TextStyle(
            fontSize: 12 * textScale,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12 * textScale,
          ),
          onTap: (index) {
            if (index == currentIndex) return;

            final routes = [
              '/home',        // 0 - Dashboard
              '/expenses',    // 1 - Despesas
              '/invites',     // 2 - Convites
              '/group',       // 3 - Grupos
              '/settings',    // 4 - Configurações
            ];

            final labels = [
              'Dashboard',
              'Despesas',
              'Convites',
              'Grupos',
              'Configurações',
            ];

            SemanticsService.announce(
              'Navegando para ${labels[index]}',
              Directionality.of(context),
            );
            

            Navigator.pushReplacementNamed(context, routes[index]);
          },
          items: [
            // 0 - Dashboard
            BottomNavigationBarItem(
              icon: Semantics(
                label: 'Dashboard',
                hint: 'Toque para ir para o Dashboard',
                child: ExcludeSemantics(
                  excluding: true,
                  child: const Icon(Icons.dashboard_outlined),
                ),
              ),
              label: 'Dashboard',
            ),

            // 1 - Despesas
            BottomNavigationBarItem(
              icon: Semantics(
                label: 'Despesas',
                hint: 'Toque para ir para Despesas',
                child: ExcludeSemantics(
                  excluding: true,
                  child: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              label: 'Despesas',
            ),

            // 2 - Convites
            BottomNavigationBarItem(
              icon: Semantics(
                label: 'Convites',
                hint: 'Toque para ver seus convites',
                child: ExcludeSemantics(
                  excluding: true,
                  child: const Icon(Icons.mail_outline),
                ),
              ),
              label: 'Convites',
            ),

            // 3 - Grupos
            BottomNavigationBarItem(
              icon: Semantics(
                label: 'Grupos',
                hint: 'Toque para ir para Grupos',
                child: ExcludeSemantics(
                  excluding: true,
                  child: const Icon(Icons.group_outlined),
                ),
              ),
              label: 'Grupos',
            ),

            // 4 - Configurações com badge
           BottomNavigationBarItem(
  icon: FutureBuilder<String>(
    future: PreferencesService.getUserName(),
    builder: (context, snapshot) {
      final currentUser = snapshot.data ?? 'Usuário';

      return Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final hasPending =
              notificationProvider.hasPendingFor(currentUser);
          final pendingCount =
              notificationProvider.pendingCountFor(currentUser);

          return Semantics(
            label: hasPending
                ? 'Configurações, $pendingCount notificações pendentes'
                : 'Configurações',
            hint: 'Toque para ir para Configurações',
            button: true,
            selected: currentIndex == 4,
            child: ExcludeSemantics(
              child: Stack(
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
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  ),
  label: 'Configurações',

),
          ],
        ),
      ),
    );
  }
}