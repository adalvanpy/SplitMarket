enum DebtStatus {
  pending,
  awaitingConfirmation,
  paid,
}

class DebtModel {
  final String participant;
  final double amount;
  final String description;
  final DebtStatus status;
  final String? proofImagePath;

  DebtModel({
    required this.participant,
    required this.amount,
    required this.description,
    this.status = DebtStatus.pending,
    this.proofImagePath,
  });

  // ============================================================
  // ✅ COPY WITH
  // ============================================================
  DebtModel copyWith({
    String? participant,
    double? amount,
    String? description,
    DebtStatus? status,
    String? proofImagePath,
  }) {
    return DebtModel(
      participant: participant ?? this.participant,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      proofImagePath: proofImagePath ?? this.proofImagePath,
    );
  }

  // ============================================================
  // ✅ TO MAP - Para salvar no Firestore/SQLite
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'participant': participant,
      'amount': amount,
      'description': description,
      'status': status.name, // ✅ Salva o nome do enum
      'proofImagePath': proofImagePath,
    };
  }

  // ============================================================
  // ✅ FROM MAP - Para carregar do Firestore/SQLite
  // ============================================================
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      participant: _toString(map['participant']) ?? '',
      amount: _toDouble(map['amount']),
      description: _toString(map['description']) ?? '',
      status: _toDebtStatus(map['status']),
      proofImagePath: _toString(map['proofImagePath']),
    );
  }

  // ============================================================
  // ✅ FROM JSON - Para APIs
  // ============================================================
  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel.fromMap(json);
  }

  // ============================================================
  // ✅ TO JSON
  // ============================================================
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ============================================================
  // ✅ STATUS LABEL (já existente, mantido)
  // ============================================================
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

  // ============================================================
  // ✅ MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA
  // ============================================================
  
  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static DebtStatus _toDebtStatus(dynamic value) {
    if (value == null) return DebtStatus.pending;
    
    // Se for String
    if (value is String) {
      // Tenta converter o nome do enum
      try {
        return DebtStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => DebtStatus.pending,
        );
      } catch (_) {
        return DebtStatus.pending;
      }
    }
    
    // Se for int (posição do enum)
    if (value is int) {
      try {
        return DebtStatus.values[value];
      } catch (_) {
        return DebtStatus.pending;
      }
    }
    
    return DebtStatus.pending;
  }
}
