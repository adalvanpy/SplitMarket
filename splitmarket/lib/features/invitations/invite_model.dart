class InviteModel {
  final String id;
  final String groupId;
  final String groupName;
  final String email;
  final String status;

  InviteModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.email,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'email': email,
      'status': status,
    };
  }

  factory InviteModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return InviteModel(
      id: id,
      groupId: map['groupId'],
      groupName: map['groupName'],
      email: map['email'],
      status: map['status'],
    );
  }
}