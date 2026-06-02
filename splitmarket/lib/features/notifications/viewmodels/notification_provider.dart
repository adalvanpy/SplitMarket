import 'package:flutter/material.dart';

import '../../../data/models/debt_model.dart';
import '../models/debt_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<DebtNotification> _notifications = [];

  int pendingCountFor(String receiver) => _notifications
      .where((notification) => notification.receiver == receiver && notification.status == DebtStatus.awaitingConfirmation)
      .length;

  bool hasPendingFor(String receiver) => pendingCountFor(receiver) > 0;

  List<DebtNotification> pendingNotificationsFor(String receiver) => _notifications
      .where((notification) => notification.receiver == receiver && notification.status == DebtStatus.awaitingConfirmation)
      .toList();

  DebtNotification? getNotificationFor({
    required String sender,
    required String receiver,
    required double amount,
  }) {
    for (final notification in _notifications) {
      if (notification.sender == sender &&
          notification.receiver == receiver &&
          notification.amount == amount) {
        return notification;
      }
    }
    return null;
  }

  void addNotification(DebtNotification notification) {
    final existing = getNotificationFor(
      sender: notification.sender,
      receiver: notification.receiver,
      amount: notification.amount,
    );
    if (existing == null) {
      _notifications.add(notification);
    } else {
      final index = _notifications.indexOf(existing);
      _notifications[index] = existing.copyWith(
        status: notification.status,
        proofImagePath: notification.proofImagePath,
      );
    }
    notifyListeners();
  }

  void confirmNotification(DebtNotification notification) {
    final index = _notifications.indexOf(notification);
    if (index < 0) return;
    _notifications[index] = notification.copyWith(status: DebtStatus.paid);
    notifyListeners();
  }

  void confirmNotificationFor({
    required String sender,
    required String receiver,
    required double amount,
  }) {
    final notification = getNotificationFor(
      sender: sender,
      receiver: receiver,
      amount: amount,
    );
    if (notification == null) return;
    final index = _notifications.indexOf(notification);
    if (index < 0) return;
    _notifications[index] = notification.copyWith(status: DebtStatus.paid);
    notifyListeners();
  }
}
