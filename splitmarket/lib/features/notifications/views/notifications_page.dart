import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/preferences_service.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../models/debt_notification.dart';
import '../viewmodels/notification_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<String>(
      future: PreferencesService.getUserName(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? 'Usuário';
        final notifications = notificationProvider.pendingNotificationsFor(currentUser);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificações'),
            backgroundColor: const Color(0xFF8E76F7),
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma pendência de confirmação no momento.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final debt = notifications[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                debt.sender,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${debt.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            debt.description,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  debt.statusLabel,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  notificationProvider.confirmNotification(debt);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Confirmação de R\$ ${debt.amount.toStringAsFixed(2)} registrada.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8E76F7),
                                ),
                                child: const Text('Confirmar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          bottomNavigationBar: const CustomBottomNavbar(currentIndex: 3),
        );
      },
    );
  }
}
