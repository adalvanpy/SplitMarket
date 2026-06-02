import 'package:flutter/material.dart';

import '../models/expense_model.dart';

import '../../core/services/expense_service.dart';

class ExpenseProvider
    extends ChangeNotifier {

  final ExpenseService _service =
      ExpenseService();

  List<ExpenseModel> despesas = [];

  bool carregando = false;

  Future<void> carregarDespesas()
      async {

    carregando = true;

    notifyListeners();

    despesas =
        await _service.getExpenses();

    carregando = false;

    notifyListeners();
  }

  Future<void> carregarDespesasPorGrupo(String grupoId) async {
    carregando = true;

    notifyListeners();

    despesas = await _service.getExpensesByGroup(grupoId);

    carregando = false;

    notifyListeners();
  }

  Future<void> limparDespesas() async {
    carregando = true;
    despesas = [];
    notifyListeners();
    carregando = false;
    notifyListeners();
  }

  Future<void> clearLocalExpenses() async {
    carregando = true;
    notifyListeners();

    await _service.clearExpenses();
    despesas = [];

    carregando = false;
    notifyListeners();
  }

  Future<void> adicionarDespesa(
    ExpenseModel expense,
  ) async {

    await _service.insertExpense(
      expense,
    );

    await carregarDespesas();
  }

  Future<void> deletarDespesa(
    int id,
  ) async {

    await _service.deleteExpense(
      id,
    );

    await carregarDespesas();
  }
}