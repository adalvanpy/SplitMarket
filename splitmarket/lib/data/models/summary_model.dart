class SummaryModel {
  final double totalExpenses;
  final int totalItems;
  final double averageExpense;

  SummaryModel({
    required this.totalExpenses,
    required this.totalItems,
    required this.averageExpense,
  });

  // ============================================================
  // ✅ COPY WITH
  // ============================================================
  SummaryModel copyWith({
    double? totalExpenses,
    int? totalItems,
    double? averageExpense,
  }) {
    return SummaryModel(
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalItems: totalItems ?? this.totalItems,
      averageExpense: averageExpense ?? this.averageExpense,
    );
  }

  // ============================================================
  // ✅ TO MAP - Para salvar no Firestore/SQLite
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'totalExpenses': totalExpenses,
      'totalItems': totalItems,
      'averageExpense': averageExpense,
    };
  }

  // ============================================================
  // ✅ FROM MAP - Para carregar do Firestore/SQLite
  // ============================================================
  factory SummaryModel.fromMap(Map<String, dynamic> map) {
    return SummaryModel(
      totalExpenses: _toDouble(map['totalExpenses']),
      totalItems: _toInt(map['totalItems']),
      averageExpense: _toDouble(map['averageExpense']),
    );
  }

  // ============================================================
  // ✅ TO JSON - Para APIs
  // ============================================================
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ============================================================
  // ✅ FROM JSON - Para APIs
  // ============================================================
  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel.fromMap(json);
  }

  // ============================================================
  // ✅ MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA
  // ============================================================
  
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

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is num) return value.toInt();
    return 0;
  }
}