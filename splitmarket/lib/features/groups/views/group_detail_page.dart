import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/expense_service.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/expense_model.dart';
import '../../expenses/views/add_expense_page.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';

class GroupDetailPage extends StatefulWidget {
  final GroupModel grupo;

  const GroupDetailPage({
    super.key,
    required this.grupo,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ExpenseService _expenseService = ExpenseService();
  late Future<List<ExpenseModel>> _despesasFuture;
  bool _showParticipants = false;
  
  Map<String, String> _userNames = {};
  bool _loadingNames = true;

  @override
  void initState() {
    super.initState();
    _loadDespesas();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    setState(() => _loadingNames = true);
    
    try {
      for (String userId in widget.grupo.membros) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (doc.exists) {
          final nome = doc.data()?['name'] ?? userId;
          _userNames[userId] = nome;
        } else {
          _userNames[userId] = userId;
        }
      }
    } catch (e) {
      print('Erro ao carregar nomes: $e');
    } finally {
      setState(() => _loadingNames = false);
    }
  }

  String _getUserName(String userId) {
    return _userNames[userId] ?? userId;
  }

  void _loadDespesas() {
    _despesasFuture = _expenseService.getExpensesByGroup(widget.grupo.id);
  }

  double _calcularTotalPago(List<ExpenseModel> despesas) {
    return despesas.fold(0.0, (sum, expense) => sum + expense.value);
  }

  Map<String, double> _calcularDividasParticipante(List<ExpenseModel> despesas) {
    final dividas = <String, double>{};

    for (String membro in widget.grupo.membros) {
      final nomeMembro = _getUserName(membro);
      dividas[nomeMembro] = 0.0;
    }

    for (final expense in despesas) {
      final valorPorPessoa = expense.value / widget.grupo.membros.length;
      for (String membro in widget.grupo.membros) {
        if (membro != expense.payer) {
          final nomeMembro = _getUserName(membro);
          dividas[nomeMembro] = (dividas[nomeMembro] ?? 0.0) + valorPorPessoa;
        }
      }
    }

    return dividas;
  }

  void _toggleParticipantes() {
    setState(() {
      _showParticipants = !_showParticipants;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.grupo.nome,
          style: const TextStyle(fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _toggleParticipantes,
            icon: Icon(
              Icons.group,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              _showParticipants ? 'Fechar' : 'Membros',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ExpenseModel>>(
            future: _despesasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _loadingNames) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar despesas: ${snapshot.error}'),
                );
              }

              final despesas = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card do grupo - MAIS VISÍVEL
                    _buildGroupHeader(context, isDark),
                    const SizedBox(height: 16),
                    
                    // Botão nova despesa
                    _buildActionButtons(context),
                    const SizedBox(height: 24),
                    
                    // Resumo de gastos
                    if (despesas.isNotEmpty) 
                      _buildResumoDebitos(context, despesas, isDark),
                    if (despesas.isNotEmpty) const SizedBox(height: 24),
                    
                    // Lista de despesas
                    _buildDespesasSection(context, despesas, isDark),
                  ],
                ),
              );
            },
          ),
          
          // Sidebar de participantes
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            left: _showParticipants ? 0 : -280,
            width: 280,
            child: _buildParticipantsSidebar(context, isDark),
          ),
          
          if (_showParticipants)
            GestureDetector(
              onTap: _toggleParticipantes,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 2),
    );
  }

  // Card do grupo - MAIS VISÍVEL E DESTACADO
  Widget _buildGroupHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E76F7), Color(0xFFB993F9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E76F7).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.grupo.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.grupo.membros.length} participantes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E76F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpensePage(grupoId: widget.grupo.id),
            ),
          );
          _loadDespesas();
          setState(() {});
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Nova despesa',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  // Sidebar de participantes - MAIS LEGÍVEL
  Widget _buildParticipantsSidebar(BuildContext context, bool isDark) {
    return Material(
      elevation: 12,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3E8FF),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Participantes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleParticipantes,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingNames
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: widget.grupo.membros.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final membroId = widget.grupo.membros[index];
                        final membroNome = _getUserName(membroId);
                        final inicial = membroNome.trim().isNotEmpty
                            ? membroNome.trim()[0].toUpperCase()
                            : '?';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF8E76F7),
                                child: Text(
                                  inicial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  membroNome,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Resumo de débitos - VALOR COM FONTE MENOR
  Widget _buildResumoDebitos(BuildContext context, List<ExpenseModel> despesas, bool isDark) {
    final dividas = _calcularDividasParticipante(despesas);
    final totalGasto = _calcularTotalPago(despesas);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFF8E76F7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFF8E76F7).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de Gastos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total Gasto: R\$ ${totalGasto.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...dividas.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'R\$ ${entry.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF8E76F7),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Lista de despesas - VALOR COM FONTE MENOR
  Widget _buildDespesasSection(
    BuildContext context,
    List<ExpenseModel> despesas,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Despesas (${despesas.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (despesas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma despesa registrada',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: despesas.length,
            itemBuilder: (context, index) {
              final expense = despesas[index];
              final valorPorPessoa = expense.value / widget.grupo.membros.length;
              final payerName = _getUserName(expense.payer);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pago por: $payerName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'R\$ ${expense.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF8E76F7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Quem deve:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.grupo.membros
                        .where((membro) => membro != expense.payer)
                        .map(
                          (membro) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getUserName(membro),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'R\$ ${valorPorPessoa.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
