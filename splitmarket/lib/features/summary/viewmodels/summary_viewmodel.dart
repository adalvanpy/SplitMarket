import '../../../data/models/expense_model.dart';

import '../../../core/services/expense_service.dart';

import '../../../data/models/summary_model.dart';

class SummaryViewModel {

  final ExpenseService _expenseService =
      ExpenseService();

  Future<SummaryModel> getSummary() async {

    final List<ExpenseModel> expenses =
        await _expenseService.getExpenses();

    double totalExpenses = 0;

    for (var expense in expenses) {

      totalExpenses += expense.value;
    }

    final int totalItems =
        expenses.length;

    final double averageExpense =
        totalItems > 0
            ? totalExpenses / totalItems
            : 0;

    return SummaryModel(

      totalExpenses: totalExpenses,

      totalItems: totalItems,

      averageExpense: averageExpense,
    );
  }
}