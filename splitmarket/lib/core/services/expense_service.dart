import '../database/database_helper.dart';
import '../../data/models/expense_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<int> insertExpense(
    ExpenseModel expense,
  )
  async{
    final db = await _databaseHelper.database;

    final id = await db.insert(
      'expenses',
      expense.toMap(),
    );

    // Try to also save to Firestore. Failure here should not break local storage.
    try {
      final firestore = FirebaseFirestore.instance;

      final firestoreMap = {
        'localId': id,
        'description': expense.description,
        'value': expense.value,
        'payer': expense.payer,
        'grupoId': expense.grupoId,
        'createdAt': expense.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      await firestore.collection('expenses').add(firestoreMap);
    } catch (e) {
      // Optional: log the error with your preferred logging. Do not rethrow.
    }

    return id;
  }
  Future<List<ExpenseModel>> getExpenses() async{
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps =
    await db.query('expenses');

    return List.generate(
      maps.length, 
      (index){
        return ExpenseModel.fromMap(
          maps[index],
        );
      },
    );
  }

  Future<List<ExpenseModel>> getExpensesByGroup(String grupoId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'grupoId = ?',
      whereArgs: [grupoId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(
      maps.length,
      (index) {
        return ExpenseModel.fromMap(
          maps[index],
        );
      },
    );
  }

  Future<int> deleteExpense(int id) async{
    final db = await _databaseHelper.database;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearExpenses() async {
    final db = await _databaseHelper.database;
    await db.delete('expenses');
  }
}