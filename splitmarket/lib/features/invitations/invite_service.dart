import 'package:cloud_firestore/cloud_firestore.dart';

class InviteService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> enviarConvite({
    required String groupId,
    required String groupName,
    required String email,
  }) async {
    await _firestore.collection('group_invites').add({
      'groupId': groupId,
      'groupName': groupName,
      'email': email,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> aceitarConvite(
    String inviteId,
    String groupId,
    String userId,
  ) async {
    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();

    final membros =
        List<String>.from(groupDoc['membros'] ?? []);

    if (!membros.contains(userId)) {
      membros.add(userId);

      await _firestore
          .collection('groups')
          .doc(groupId)
          .update({
        'membros': membros,
      });
    }

    await _firestore
        .collection('group_invites')
        .doc(inviteId)
        .update({
      'status': 'accepted',
    });
  }
}