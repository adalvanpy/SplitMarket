// lib/data/models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String nome;
  final List<String> membros;
  final String criadorId;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.nome,
    required this.membros,
    required this.criadorId,
    required this.createdAt,
  });

  // ============================================================
  // ✅ COPY WITH
  // ============================================================
  GroupModel copyWith({
    String? id,
    String? nome,
    List<String>? membros,
    String? criadorId,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      membros: membros ?? this.membros,
      criadorId: criadorId ?? this.criadorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // ✅ TO MAP - Para salvar no Firestore/SQLite
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'membros': membros,
      'criadorId': criadorId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ============================================================
  // ✅ FROM MAP - Para carregar do Firestore/SQLite
  // ============================================================
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: _toString(map['id']) ?? '',
      nome: _toString(map['nome']) ?? '',
      membros: _toStringList(map['membros']),
      criadorId: _toString(map['criadorId']) ?? '',
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
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
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel.fromMap(json);
  }

  // ============================================================
  // ✅ MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA
  // ============================================================
  
  /// Converte qualquer valor para String
  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Converte qualquer valor para DateTime
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    
    // Se for Timestamp (Firestore)
    if (value is Timestamp) return value.toDate();
    
    // Se for DateTime
    if (value is DateTime) return value;
    
    // Se for String
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    return null;
  }

  /// Converte para List<String> segura
  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    
    // Se já for List<String>
    if (value is List<String>) return value;
    
    // Se for List<dynamic> ou List<Object?>
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    
    return [];
  }
}