class ExpenseModel {

  final int? id;
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

  Map<String, dynamic> toMap(){
    return{
      'id': id, 
      'description': description,
      'value': value,
      'payer': payer,
      'grupoId': grupoId,
      'createdAt': createdAt?.toIso8601String(),
      'location': location,
    };
  }
  factory ExpenseModel.fromMap(
    Map<String, dynamic> map,
  ){
    return ExpenseModel(
      id: map['id'],
      description: map['description'],
      value: map['value'],
      payer: map['payer'],
      grupoId: map['grupoId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      location: map['location'],
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      description: json['description'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      payer: json['payer'] ?? '',
      grupoId: json['grupoId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      location: json['location'],
    );
  }
}