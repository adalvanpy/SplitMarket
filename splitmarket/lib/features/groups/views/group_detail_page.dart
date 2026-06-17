import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  // 🎯 Focus nodes
  final FocusNode _addExpenseFocusNode = FocusNode();
  final FocusNode _toggleMembersFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadDespesas();
    _loadUserNames();
  }

  @override
  void dispose() {
    _addExpenseFocusNode.dispose();
    _toggleMembersFocusNode.dispose();
    super.dispose();
  }

  // 🗣️ Método para anunciar ao TalkBack
  void _announceToTalkBack(String message) {
    if (mounted) {
      SemanticsService.announce(
        message,
        Directionality.of(context),
      );
    }
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
      debugPrint('Erro ao carregar nomes: $e');
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
      if (_showParticipants) {
        _announceToTalkBack('Lista de participantes aberta');
      } else {
        _announceToTalkBack('Lista de participantes fechada');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔤 Fonte dinâmica
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Detalhes do grupo ${widget.grupo.nome}',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Semantics(
            label: 'Grupo: ${widget.grupo.nome}',
            child: Text(
              widget.grupo.nome,
              style: TextStyle(fontSize: 18 * textScale),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          elevation: 0,
          centerTitle: true,
          actions: [
            Semantics(
              button: true,
              label: _showParticipants ? 'Fechar lista de membros' : 'Abrir lista de membros',
              hint: _showParticipants ? 'Toque para fechar' : 'Toque para ver os membros do grupo',
              child: TextButton.icon(
                focusNode: _toggleMembersFocusNode,
                onPressed: _toggleParticipantes,
                icon: Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 20 * textScale,
                ),
                label: Text(
                  _showParticipants ? 'Fechar' : 'Membros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * textScale,
                  ),
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
                  return Center(
                    child: Semantics(
                      label: 'Carregando despesas do grupo',
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Semantics(
                      label: 'Erro ao carregar despesas',
                      child: Text(
                        'Erro ao carregar despesas: ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 16 * textScale,
                        ),
                      ),
                    ),
                  );
                }

                final despesas = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGroupHeader(context, isDark, textScale),
                      const SizedBox(height: 16),
                      
                      _buildActionButtons(context, textScale),
                      const SizedBox(height: 24),
                      
                      _buildDespesasSection(
                        context,
                        despesas,
                        isDark,
                        textScale,
                      ),
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
              child: _buildParticipantsSidebar(context, isDark, textScale),
            ),
            
            if (_showParticipants)
              GestureDetector(
                onTap: _toggleParticipantes,
                child: Semantics(
                  label: 'Fechar lista de participantes',
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 2),
      ),
    );
  }

  // ============================================================
  // HEADER DO GRUPO
  // ============================================================
  Widget _buildGroupHeader(
    BuildContext context,
    bool isDark,
    double textScale,
  ) {
    return Semantics(
      container: true,
      label: 'Informações do grupo ${widget.grupo.nome}',
      child: Container(
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
        child: Row(
          children: [
            ExcludeSemantics(
              excluding: true,
              child: Container(
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    label: 'Nome do grupo: ${widget.grupo.nome}',
                    child: Text(
                      widget.grupo.nome,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: '${widget.grupo.membros.length} participantes',
                    child: Text(
                      '${widget.grupo.membros.length} participantes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13 * textScale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTÕES DE AÇÃO
  // ============================================================
  Widget _buildActionButtons(
    BuildContext context,
    double textScale,
  ) {
    return Semantics(
      button: true,
      label: 'Nova despesa',
      hint: 'Toque para adicionar uma nova despesa ao grupo',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          focusNode: _addExpenseFocusNode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E76F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            _announceToTalkBack('Abrindo tela para adicionar despesa');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddExpensePage(grupoId: widget.grupo.id),
              ),
            );
            _loadDespesas();
            setState(() {});
            _announceToTalkBack('Lista de despesas atualizada');
          },
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Nova despesa',
            style: TextStyle(
              fontSize: 15 * textScale,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR DE PARTICIPANTES
  // ============================================================
  Widget _buildParticipantsSidebar(
    BuildContext context,
    bool isDark,
    double textScale,
  ) {
    return Semantics(
      container: true,
      label: 'Lista de participantes do grupo',
      child: Material(
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
                  Semantics(
                    header: true,
                    label: 'Participantes',
                    child: Expanded(
                      child: Text(
                        'Participantes',
                        style: TextStyle(
                          fontSize: 18 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Fechar lista',
                    hint: 'Toque para fechar a lista de participantes',
                    child: IconButton(
                      onPressed: _toggleParticipantes,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loadingNames
                    ? Center(
                        child: Semantics(
                          label: 'Carregando participantes',
                          child: const CircularProgressIndicator(),
                        ),
                      )
                    : Semantics(
                        label: '${widget.grupo.membros.length} participantes',
                        child: ListView.separated(
                          itemCount: widget.grupo.membros.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final membroId = widget.grupo.membros[index];
                            final membroNome = _getUserName(membroId);
                            final inicial = membroNome.trim().isNotEmpty
                                ? membroNome.trim()[0].toUpperCase()
                                : '?';
                            return Semantics(
                              container: true,
                              label: 'Participante ${index + 1}: $membroNome',
                              child: Container(
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
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 * textScale,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        membroNome,
                                        style: TextStyle(
                                          fontSize: 14 * textScale,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LISTA DE DESPESAS
  // ============================================================
  Widget _buildDespesasSection(
    BuildContext context,
    List<ExpenseModel> despesas,
    bool isDark,
    double textScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: 'Histórico de Despesas, ${despesas.length} itens',
          child: Text(
            'Histórico de Despesas (${despesas.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15 * textScale,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (despesas.isEmpty)
          _buildEmptyState(isDark, textScale)
        else
          Semantics(
            label: 'Lista de despesas, ${despesas.length} itens',
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: despesas.length,
              itemBuilder: (context, index) {
                final expense = despesas[index];
                return _buildExpenseCard(
                  context,
                  expense,
                  isDark,
                  textScale,
                  index,
                );
              },
            ),
          ),
      ],
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================
  Widget _buildEmptyState(bool isDark, double textScale) {
    return Center(
      child: Semantics(
        label: 'Nenhuma despesa registrada',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              ExcludeSemantics(
                excluding: true,
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 48 * textScale,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma despesa registrada',
                style: TextStyle(
                  fontSize: 14 * textScale,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Toque no botão Nova despesa para adicionar',
                child: Text(
                  'Toque em "Nova despesa" para começar',
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE DESPESA
  // ============================================================
  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel expense,
    bool isDark,
    double textScale,
    int index,
  ) {
    final valorPorPessoa = expense.value / widget.grupo.membros.length;
    final payerName = _getUserName(expense.payer);

    return Semantics(
      container: true,
      label: 'Despesa ${index + 1}: ${expense.description}, valor R\$ ${expense.value.toStringAsFixed(2)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade200,
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
                      Semantics(
                        label: 'Descrição: ${expense.description}',
                        child: Text(
                          expense.description,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * textScale,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        label: 'Pago por: $payerName',
                        child: Text(
                          'Pago por: $payerName',
                          style: TextStyle(
                            fontSize: 12 * textScale,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Valor: R\$ ${expense.value.toStringAsFixed(2)}',
                  child: Text(
                    'R\$ ${expense.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14 * textScale,
                      color: const Color(0xFF8E76F7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Semantics(
              label: 'Divisão da despesa',
              child: Text(
                'Divisão',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12 * textScale,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...widget.grupo.membros.map((membro) {
              final nome = _getUserName(membro);
              if (membro == expense.payer) {
                final payerNet = (expense.value - valorPorPessoa);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        label: nome,
                        child: Text(
                          nome,
                          style: TextStyle(
                            fontSize: 12 * textScale,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Recebe R\$ ${payerNet.toStringAsFixed(2)}',
                        child: Text(
                          'R\$ ${payerNet.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12 * textScale,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        label: nome,
                        child: Text(
                          nome,
                          style: TextStyle(
                            fontSize: 12 * textScale,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Paga R\$ ${valorPorPessoa.toStringAsFixed(2)}',
                        child: Text(
                          'R\$ ${valorPorPessoa.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12 * textScale,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }).toList(),
          ],
        ),
      ),
    );
  }
}
