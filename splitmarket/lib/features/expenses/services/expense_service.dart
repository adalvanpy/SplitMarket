import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<int> insertExpense(
    ExpenseModel expense,
  )
  async{
    final db = await _databaseHelper.database;

    return await db.insert(
      'expenses',
      expense.toMap(),
    );
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
  Future<int> deleteExpense(int id) async{
    final db = await _databaseHelper.database;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}