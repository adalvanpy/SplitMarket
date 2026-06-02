import '../../../data/models/debt_model.dart';

class DebtNotification {
  final String sender;
  final String receiver;
  final double amount;
  final String description;
  final DebtStatus status;
  final String? proofImagePath;

  DebtNotification({
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.description,
    this.status = DebtStatus.pending,
    this.proofImagePath,
  });

  DebtNotification copyWith({
    String? sender,
    String? receiver,
    double? amount,
    String? description,
    DebtStatus? status,
    String? proofImagePath,
  }) {
    return DebtNotification(
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      proofImagePath: proofImagePath ?? this.proofImagePath,
    );
  }

  String get statusLabel {
    switch (status) {
      case DebtStatus.paid:
        return 'Pago';
      case DebtStatus.awaitingConfirmation:
        return 'Aguardando confirmação';
      default:
        return 'Pendente';
    }
  }
}
