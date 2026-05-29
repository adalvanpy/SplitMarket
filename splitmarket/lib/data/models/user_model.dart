// lib/models/user_model.dart
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
  
  // Converter para Map (para salvar no Firestore)
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
  
  // Criar UserModel a partir do Firestore
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin']) 
          : null,
    );
  }
  
  // Cópia com modificações
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
}