import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../core/services/preferences_service.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../models/debt_notification.dart';
import '../viewmodels/notification_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔤 Fonte dinâmica
    final textScale = MediaQuery.of(context).textScaleFactor;
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Tela de notificações',
      child: FutureBuilder<String>(
        future: PreferencesService.getUserName(),
        builder: (context, snapshot) {
          final currentUser = snapshot.data ?? 'Usuário';
          final notifications = notificationProvider.pendingNotificationsFor(currentUser);

          return Scaffold(
            appBar: AppBar(
              title: Semantics(
                header: true,
                label: 'Notificações',
                child: Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 18 * textScale,
                  ),
                ),
              ),
              backgroundColor: const Color(0xFF8E76F7),
              elevation: 0,
            ),
            body: notifications.isEmpty
                ? _buildEmptyState(context, isDark, textScale)
                : Semantics(
                    label: 'Lista de notificações, ${notifications.length} itens',
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final debt = notifications[index];
                        return _buildNotificationCard(
                          context,
                          debt,
                          index,
                          isDark,
                          textScale,
                          notificationProvider,
                        );
                      },
                    ),
                  ),
            bottomNavigationBar: const CustomBottomNavbar(currentIndex: 4),
          );
        },
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================
  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    double textScale,
  ) {
    return Center(
      child: Semantics(
        label: 'Nenhuma pendência de confirmação no momento',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              excluding: true,
              child: Icon(
                Icons.notifications_off_outlined,
                size: 80 * textScale,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Nenhuma pendência de confirmação no momento.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontSize: 16 * textScale,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Todas as suas notificações foram confirmadas',
              child: Text(
                'Tudo em dia! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14 * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE NOTIFICAÇÃO
  // ============================================================
  Widget _buildNotificationCard(
    BuildContext context,
    dynamic debt,
    int index,
    bool isDark,
    double textScale,
    NotificationProvider notificationProvider,
  ) {
    return Semantics(
      container: true,
      label: 'Notificação ${index + 1}: ${debt.sender} enviou R\$ ${debt.amount.toStringAsFixed(2)}',
      child: Container(
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
                Expanded(
                  child: Semantics(
                    label: 'Remetente: ${debt.sender}',
                    child: Text(
                      debt.sender,
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: 'Valor: R\$ ${debt.amount.toStringAsFixed(2)}',
                  child: Text(
                    'R\$ ${debt.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * textScale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: debt.description,
              child: Text(
                debt.description,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontSize: 14 * textScale,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Semantics(
                  label: 'Status: ${debt.statusLabel}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      debt.statusLabel,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12 * textScale,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Confirmar pagamento de ${debt.sender}',
                  hint: 'Toque para confirmar que recebeu o pagamento',
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmNotification(
                        context,
                        debt,
                        notificationProvider,
                        textScale,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E76F7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MÉTODO CONFIRMAR NOTIFICAÇÃO
  // ============================================================
  void _confirmNotification(
    BuildContext context,
    dynamic debt,
    NotificationProvider notificationProvider,
    double textScale,
  ) {
    // 🗣️ Anúncio para TalkBack
    SemanticsService.announce(
      'Confirmando pagamento de R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.sender}',
      Directionality.of(context),
    );

    // Mostrar diálogo de confirmação
    showDialog(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Confirmar recebimento',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Confirmar recebimento',
            child: Text(
              'Confirmar recebimento',
              style: TextStyle(
                fontSize: 20 * textScale,
              ),
            ),
          ),
          content: Semantics(
            label: 'Você confirma que recebeu R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.sender}?',
            child: Text(
              'Você confirma que recebeu R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.sender}?',
              style: TextStyle(
                fontSize: 16 * textScale,
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar confirmação',
              child: TextButton(
                onPressed: () {
                  SemanticsService.announce(
                    'Confirmação cancelada',
                    Directionality.of(context),
                  );
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14 * textScale,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Confirmar recebimento',
              hint: 'Confirmar que você recebeu o pagamento',
              child: ElevatedButton(
                onPressed: () {
                  // Confirmar no provider
                  notificationProvider.confirmNotification(debt);
                  
                  Navigator.of(context).pop();
                  
                  // Anúncio de sucesso
                  SemanticsService.announce(
                    'Pagamento confirmado com sucesso',
                    Directionality.of(context),
                  );
                  
                  // SnackBar de sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Semantics(
                        label: 'Confirmação de R\$ ${debt.amount.toStringAsFixed(2)} registrada com sucesso',
                        child: Text(
                          'Confirmação de R\$ ${debt.amount.toStringAsFixed(2)} registrada.',
                        ),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 14 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
