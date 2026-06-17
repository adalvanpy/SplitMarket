import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String? id;
  final String description;
  final double value;
  final String payer;
  final String? grupoId;
  final DateTime? createdAt;
  final String? location;

  ExpenseModel({
    this.id,
    required this.description,
    required this.value,
    required this.payer,
    this.grupoId,
    this.createdAt,
    this.location,
  });

  // ============================================================
  // ✅ TO MAP - Para salvar no Firestore e SQLite
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value, // ✅ double
      'payer': payer,
      'grupoId': grupoId,
      'createdAt': createdAt?.toIso8601String(),
      'location': location,
    };
  }

  // ============================================================
  // ✅ FROM MAP - CORRIGIDO para aceitar int, double ou String
  // ============================================================
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: _toString(map['id']),
      description: _toString(map['description']) ?? '',
      value: _toDouble(map['value']), // ✅ CONVERTE QUALQUER TIPO
      payer: _toString(map['payer']) ?? '',
      grupoId: _toString(map['grupoId']),
      createdAt: _toDateTime(map['createdAt']),
      location: _toString(map['location']),
    );
  }

  // ============================================================
  // ✅ FROM JSON - Para dados do Firestore (já corrigido)
  // ============================================================
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: _toString(json['id']),
      description: _toString(json['description']) ?? '',
      value: _toDouble(json['value']), // ✅ CONVERTE QUALQUER TIPO
      payer: _toString(json['payer']) ?? '',
      grupoId: _toString(json['grupoId']),
      createdAt: _toDateTime(json['createdAt']),
      location: _toString(json['location']),
    );
  }

  // ============================================================
  // ✅ MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA
  // ============================================================
  
  /// Converte qualquer valor para String
  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Converte qualquer valor para double (int, double, String)
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    
    // Se já for double
    if (value is double) return value;
    
    // Se for int (caso do Android SQLite)
    if (value is int) return value.toDouble();
    
    // Se for String (caso da Web)
    if (value is String) {
      // Remove vírgula e substitui por ponto
      final cleaned = value.replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    
    // Se for num (genérico)
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

  /// Converte qualquer valor para DateTime
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    
    // Se já for Timestamp (Firestore)
    if (value is Timestamp) return value.toDate();
    
    // Se já for DateTime
    if (value is DateTime) return value;
    
    // Se for String
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    return null;
  }
}