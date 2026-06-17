// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;           // UID do Firebase Auth
  final String email;
  final String name;         // Nome do usuário
  final String? avatar;      // URL da foto (opcional)
  final DateTime createdAt;  // Data de criação
  final DateTime? lastLogin; // Último login
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.lastLogin,
  });
  
  // ============================================================
  // ✅ TO MAP - Para salvar no Firestore
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
  
  // ============================================================
  // ✅ FROM MAP - CORRIGIDO para aceitar diferentes tipos
  // ============================================================
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: _toString(map['email']) ?? '',
      name: _toString(map['name']) ?? '',
      avatar: _toString(map['avatar']),
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      lastLogin: _toDateTime(map['lastLogin']),
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
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toString(json['id']) ?? '',
      email: _toString(json['email']) ?? '',
      name: _toString(json['name']) ?? '',
      avatar: _toString(json['avatar']),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      lastLogin: _toDateTime(json['lastLogin']),
    );
  }
  
  // ============================================================
  // ✅ COPY WITH
  // ============================================================
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
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
}