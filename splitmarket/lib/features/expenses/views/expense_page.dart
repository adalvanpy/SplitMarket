import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final FocusNode _addButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).carregarDespesas();
    });
  }

  @override
  void dispose() {
    _addButtonFocusNode.dispose();
    super.dispose();
  }

  void _announceToTalkBack(String message) {
    if (mounted) {
      SemanticsService.announce(
        message,
        Directionality.of(context),
      );
    }
  }

  double totalExpenses(List<ExpenseModel> expenses) {
    double total = 0;
    for (var expense in expenses) {
      total += expense.value;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Semantics(
      container: true,
      label: 'Tela de despesas',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // ============================================
            // Cabeçalho
            // ============================================
            Semantics(
              label: 'Cabeçalho - Suas Despesas',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 50, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8E76F7),
                      Color(0xFFB993F9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          button: true,
                          label: 'Voltar',
                          hint: 'Toque para voltar à tela anterior',
                          child: IconButton(
                            onPressed: () {
                              _announceToTalkBack('Voltando para tela anterior');
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        
                        Semantics(
                          header: true,
                          label: 'Suas Despesas - título da página',
                          child: Text(
                            'Suas Despesas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        Semantics(
                          button: true,
                          label: 'Adicionar despesa',
                          hint: 'Toque para adicionar uma nova despesa',
                          child: IconButton(
                            focusNode: _addButtonFocusNode,
                            onPressed: () async {
                              _announceToTalkBack('Abrindo tela para adicionar despesa');
                              await Navigator.pushNamed(
                                context,
                                '/add-expense',
                              );
                              Provider.of<ExpenseProvider>(
                                context,
                                listen: false,
                              ).carregarDespesas();
                              _announceToTalkBack('Lista de despesas atualizada');
                            },
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'Total acumulado',
                            child: Text(
                              'Total acumulado',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16 * textScale,
                              ),
                            ),
                          ),
                          Consumer<ExpenseProvider>(
                            builder: (context, provider, child) {
                              final total = totalExpenses(provider.despesas);
                              return Semantics(
                                label: 'Total: R\$ $total',
                                child: Text(
                                  'R\$ ${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36 * textScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================
            // Lista de Despesas
            // ============================================
            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.carregando) {
                    return Center(
                      child: Semantics(
                        label: 'Carregando despesas...',
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (provider.despesas.isEmpty) {
                    return _buildEmptyState(textScale);
                  }

                  return Semantics(
                    label: 'Lista de despesas, ${provider.despesas.length} itens',
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      itemCount: provider.despesas.length,
                      itemBuilder: (context, index) {
                        final expense = provider.despesas[index];
                        return _buildExpenseCard(
                          context,
                          expense,
                          textScale,
                          index,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 1),
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO - CORRIGIDO
  // ============================================================
  Widget _buildEmptyState(double textScale) {
    return Center(
      child: Semantics(
        label: 'Nenhuma despesa cadastrada',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ CORRIGIDO: Usando ExcludeSemantics
            ExcludeSemantics(
              excluding: true,
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80 * textScale,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma despesa cadastrada',
              style: TextStyle(
                fontSize: 18 * textScale,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Toque no botão mais para adicionar sua primeira despesa',
              child: Text(
                'Toque no botão + para adicionar',
                style: TextStyle(
                  fontSize: 14 * textScale,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE DESPESA - CORRIGIDO
  // ============================================================
  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel expense,
    double textScale,
    int index,
  ) {
    return Semantics(
      container: true,
      label: 'Despesa ${index + 1}: ${expense.description}, valor R\$ ${expense.value.toStringAsFixed(2)}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ExcludeSemantics(
            excluding: true,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.attach_money,
                color: Color(0xFF8E76F7),
              ),
            ),
          ),
          title: Text(
            expense.description,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16 * textScale,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Pago por: ${expense.payer}',
                child: Text(
                  'Pago por: ${expense.payer}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14 * textScale,
                  ),
                ),
              ),
              if (expense.location != null && expense.location!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Semantics(
                    label: 'Localização: ${expense.location}',
                    child: Text(
                      '📍 ${expense.location}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14 * textScale,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Valor: R\$ ${expense.value.toStringAsFixed(2)}',
                child: Text(
                  'R\$ ${expense.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE57373),
                    fontSize: 16 * textScale,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Deletar despesa ${expense.description}',
                hint: 'Toque para excluir esta despesa',
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                  ),
                  onPressed: () async {
                    _announceToTalkBack('Deletando despesa: ${expense.description}');
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Semantics(
                          header: true,
                          child: const Text('Confirmar exclusão'),
                        ),
                        content: Semantics(
                          label: 'Tem certeza que deseja deletar esta despesa?',
                          child: Text('Deseja deletar "${expense.description}"?'),
                        ),
                        actions: [
                          Semantics(
                            button: true,
                            label: 'Cancelar',
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Confirmar exclusão',
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Deletar'),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await Provider.of<ExpenseProvider>(
                        context,
                        listen: false,
                      ).deletarDespesa(
                        expense.id!,
                      );
                      _announceToTalkBack('Despesa deletada com sucesso');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}