import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/preferences_service.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../../../shared/widgets/responsive_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Usuário';
  String _currentGroup = 'Casa';
  bool _showReceivables = false;
  bool _showPayables = false;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final groupProvider =
        Provider.of<GroupProvider>(context, listen: false);

    await Future.wait([
      expenseProvider.carregarDespesas(),
      groupProvider.carregarGrupos(),
    ]);

    await _loadUserNameFromFirestore();

    if (!mounted) return;

    setState(() {
      _currentGroup = groupProvider.grupos.isNotEmpty
          ? groupProvider.grupos.first.nome
          : 'Casa';
    });
  }

  Future<void> _loadUserNameFromFirestore() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (doc.exists) {
          final nome = doc.data()?['name'] ?? 'Usuário';
          setState(() {
            _userName = nome;
            _isLoadingName = false;
          });
          await PreferencesService.saveUserName(nome);
        } else {
          final email = FirebaseAuth.instance.currentUser?.email;
          setState(() {
            _userName = email?.split('@')[0] ?? 'Usuário';
            _isLoadingName = false;
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar nome: $e');
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  double _totalReceivable(List<ExpenseModel> expenses) {
    return expenses
        .where((expense) => expense.payer == _userName)
        .fold(0.0, (sum, expense) => sum + expense.value);
  }

  double _totalPayable(List<ExpenseModel> expenses) {
    return expenses
        .where((expense) => expense.payer != _userName)
        .fold(0.0, (sum, expense) => sum + expense.value);
  }

  List<DebtModel> _buildReceivables(List<ExpenseModel> expenses) {
    return expenses
        .where((expense) => expense.payer == _userName)
        .map(
          (expense) => DebtModel(
            participant: 'Todos os participantes',
            amount: expense.value,
            description: expense.description,
          ),
        )
        .toList();
  }

  List<DebtModel> _buildPayables(List<ExpenseModel> expenses) {
    final Map<String, double> aggregated = {};

    for (var expense in expenses.where((expense) => expense.payer != _userName)) {
      aggregated[expense.payer] =
          (aggregated[expense.payer] ?? 0) + expense.value;
    }

    return aggregated.entries
        .map(
          (entry) => DebtModel(
            participant: entry.key,
            amount: entry.value,
            description: 'Total devido a ${entry.key}',
          ),
        )
        .toList();
  }

  void _toggleReceivables() {
    setState(() {
      _showReceivables = !_showReceivables;
      if (_showReceivables) _showPayables = false;
    });
  }

  void _togglePayables() {
    setState(() {
      _showPayables = !_showPayables;
      if (_showPayables) _showReceivables = false;
    });
  }

  Future<void> _showCreateGroupDialog() async {
    final TextEditingController groupNameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Grupo'),
        content: TextField(
          controller: groupNameController,
          decoration: const InputDecoration(
            hintText: 'Ex: Viagem, Casa, Faculdade...',
            labelText: 'Nome do grupo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                final groupProvider = Provider.of<GroupProvider>(
                  context,
                  listen: false,
                );
                await groupProvider.criarGrupo(groupName);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Grupo "$groupName" criado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadDashboardData();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E76F7),
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSelectGroupDialog() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    
    if (groupProvider.grupos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum grupo criado. Crie um novo grupo!'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Grupo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groupProvider.grupos.length,
            itemBuilder: (context, index) {
              final grupo = groupProvider.grupos[index];
              return ListTile(
                leading: const Icon(Icons.group, color: Color(0xFF8E76F7)),
                title: Text(grupo.nome),
                subtitle: Text('${grupo.membros.length} membros'),
                onTap: () {
                  setState(() {
                    _currentGroup = grupo.nome;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Grupo alterado para "$_currentGroup"'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Card adaptativo - mantém tamanho original no mobile, aumenta no tablet/desktop
  Widget _buildSummaryCard({
    required String title,
    required double value,
    required bool active,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: active
              ? accentColor.withAlpha((0.12 * 255).round())
              : (isDark ? const Color(0xFF2D2D2D) : Colors.white),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: active ? accentColor : (isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade200),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailList({
    required String title,
    required List<DebtModel> items,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Nenhum registro encontrado.',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final debt = items[index];
            return Container(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.participant,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debt.description,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${debt.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final expenses = expenseProvider.despesas;
    final totalReceivable = _totalReceivable(expenses);
    final totalPayable = _totalPayable(expenses);
    final receivables = _buildReceivables(expenses);
    final payables = _buildPayables(expenses);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: expenseProvider.carregando || _isLoadingName
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 20 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $_userName',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veja como está sua posição no grupo hoje.',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Cards lado a lado
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'A receber',
                            value: totalReceivable,
                            active: _showReceivables,
                            accentColor: Colors.green,
                            onTap: _toggleReceivables,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'A pagar',
                            value: totalPayable,
                            active: _showPayables,
                            accentColor: Colors.red,
                            onTap: _togglePayables,
                          ),
                        ),
                      ],
                    ),
                    
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showReceivables
                          ? _buildDetailList(
                              title: 'Quem deve para você',
                              items: receivables,
                              accentColor: Colors.green,
                            )
                          : _showPayables
                              ? _buildDetailList(
                                  title: 'Quem você deve',
                                  items: payables,
                                  accentColor: Colors.red,
                                )
                              : Padding(
                                  key: const ValueKey('empty'),
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    'Toque em um card para ver os participantes.',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      fontSize: isMobile ? 13 : 14,
                                    ),
                                  ),
                                ),
                    ),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Card do grupo
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grupo atual',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _showCreateGroupDialog,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFF8E76F7),
                                    ),
                                    iconSize: isMobile ? 22 : 24,
                                    tooltip: 'Criar novo grupo',
                                  ),
                                  IconButton(
                                    onPressed: _showSelectGroupDialog,
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      color: Color(0xFF8E76F7),
                                    ),
                                    iconSize: isMobile ? 22 : 24,
                                    tooltip: 'Trocar grupo',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentGroup,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Você participa do grupo $_currentGroup e acompanha todas as despesas do grupo.',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 0),
    );
  }
}