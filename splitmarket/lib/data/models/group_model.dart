// lib/data/models/group_model.dart
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'membros': membros,
      'criadorId': criadorId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}