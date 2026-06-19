import 'package:cloud_firestore/cloud_firestore.dart';

class DebtService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<bool> possuiDividasPendentes(
    String userId,
    String grupoId,
  ) async {
    final result = await _firestore
        .collection('debts')
        .where('grupoId', isEqualTo: grupoId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return result.docs.isNotEmpty;
  }
}