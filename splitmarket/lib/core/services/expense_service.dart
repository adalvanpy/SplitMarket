import '../database/database_helper.dart';
import '../../data/models/expense_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExpenseService {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<int> insertExpense(
    ExpenseModel expense,
  )
  async{
    // On web we don't have local sqflite DB available; use Firestore as primary storage.
    if (kIsWeb) {
      try {
        final firestore = FirebaseFirestore.instance;
        final firestoreMap = {
          'description': expense.description,
          'value': expense.value,
          'payer': expense.payer,
          'grupoId': expense.grupoId,
          'createdAt': expense.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'location': expense.location,
        };
        await firestore.collection('expenses').add(firestoreMap);
      } catch (e) {
        // Optional: log error
      }
      // No local integer id on web
      return 0;
    }

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
        'location': expense.location,
      };

      await firestore.collection('expenses').add(firestoreMap);
    } catch (e) {
      // Optional: log the error with your preferred logging. Do not rethrow.
    }

    return id;
  }
  Future<List<ExpenseModel>> getExpenses() async{
    if (kIsWeb) {
      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore.collection('expenses').get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          // Normalize fields for fromJson
          return ExpenseModel.fromJson({
            'id': null,
            'description': data['description'] ?? '',
            'value': (data['value'] ?? 0).toDouble(),
            'payer': data['payer'] ?? '',
            'grupoId': data['grupoId'],
            'createdAt': data['createdAt'],
            'location': data['location'],
          });
        }).toList();

        // Optionally sort by createdAt desc
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));

        return list;
      } catch (e) {
        return [];
      }
    }

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
    if (kIsWeb) {
      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore
            .collection('expenses')
            .where('grupoId', isEqualTo: grupoId)
            .get();

        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return ExpenseModel.fromJson({
            'id': null,
            'description': data['description'] ?? '',
            'value': (data['value'] ?? 0).toDouble(),
            'payer': data['payer'] ?? '',
            'grupoId': data['grupoId'],
            'createdAt': data['createdAt'],
            'location': data['location'],
          });
        }).toList();

        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));

        return list;
      } catch (e) {
        return [];
      }
    }

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