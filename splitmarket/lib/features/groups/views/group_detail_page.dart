import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Map<String, String> _userNames = {};
  bool _loadingNames = true;
  bool _saindoDoGrupo = false;

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

  void _announceToTalkBack(String message) {
    if (mounted) {
      SemanticsService.announce(message, Directionality.of(context));
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
          _userNames[userId] = doc.data()?['name'] ?? userId;
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

  String _getUserName(String userId) => _userNames[userId] ?? userId;

  void _loadDespesas() {
    _despesasFuture = _expenseService.getExpensesByGroup(widget.grupo.id);
  }

  // ============================================================
  // SAIR DO GRUPO
  // ============================================================
  Future<void> _sairDoGrupo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica dívidas pendentes
    final despesas = await _expenseService.getExpensesByGroup(widget.grupo.id);
    final userName = _getUserName(uid);

    double totalDevendo = 0;
    for (final expense in despesas) {
      if (expense.payer != uid) {
        final share = expense.value / widget.grupo.membros.length;
        totalDevendo += share;
      }
    }

    double totalAReceber = 0;
    for (final expense in despesas) {
      if (expense.payer == uid) {
        final share = expense.value / widget.grupo.membros.length;
        totalAReceber += share * (widget.grupo.membros.length - 1);
      }
    }

    if (!mounted) return;

    if (totalDevendo > 0 || totalAReceber > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Não é possível sair'),
          content: Text(
            totalDevendo > 0
                ? 'Você possui R\$ ${totalDevendo.toStringAsFixed(2)} em dívidas pendentes neste grupo. Quite-as antes de sair.'
                : 'Você possui R\$ ${totalAReceber.toStringAsFixed(2)} a receber neste grupo. Resolva as pendências antes de sair.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirma saída
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do grupo'),
        content: Text(
          'Tem certeza que deseja sair do grupo "${widget.grupo.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saindoDoGrupo = true);

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.grupo.id);

      final groupDoc = await groupRef.get();
      final membros = List<String>.from(groupDoc['membros']);
      membros.remove(uid);

      await groupRef.update({'membros': membros});

      if (!mounted) return;
      _announceToTalkBack('Você saiu do grupo ${widget.grupo.nome}');
      Navigator.pop(context, true); // volta para a lista de grupos
    } catch (e) {
      debugPrint('Erro ao sair do grupo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair do grupo: $e')),
      );
    } finally {
      if (mounted) setState(() => _saindoDoGrupo = false);
    }
  }

  void _toggleParticipantes() {
    setState(() {
      _showParticipants = !_showParticipants;
      _announceToTalkBack(
        _showParticipants
            ? 'Lista de participantes aberta'
            : 'Lista de participantes fechada',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
              label: _showParticipants
                  ? 'Fechar lista de membros'
                  : 'Abrir lista de membros',
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
                  style: TextStyle(color: Colors.white, fontSize: 14 * textScale),
                ),
              ),
            ),
            // Botão Sair do Grupo
            Semantics(
              button: true,
              label: 'Sair do grupo',
              hint: 'Toque para sair deste grupo',
              child: _saindoDoGrupo
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      tooltip: 'Sair do grupo',
                      onPressed: _sairDoGrupo,
                    ),
            ),
          ],
        ),
        body: Stack(
          children: [
            FutureBuilder<List<ExpenseModel>>(
              future: _despesasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _loadingNames) {
                  return Center(
                    child: Semantics(
                      label: 'Carregando despesas do grupo',
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar despesas: ${snapshot.error}',
                      style: TextStyle(fontSize: 16 * textScale),
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
                      _buildDespesasSection(context, despesas, isDark, textScale),
                    ],
                  ),
                );
              },
            ),
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
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 3),
      ),
    );
  }

  // ============================================================
  // HEADER DO GRUPO
  // ============================================================
  Widget _buildGroupHeader(BuildContext context, bool isDark, double textScale) {
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
                child: const Icon(Icons.group, color: Colors.white, size: 24),
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
  Widget _buildActionButtons(BuildContext context, double textScale) {
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
          label: Text('Nova despesa', style: TextStyle(fontSize: 15 * textScale)),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR DE PARTICIPANTES
  // ============================================================
  Widget _buildParticipantsSidebar(
      BuildContext context, bool isDark, double textScale) {
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
          padding: const EdgeInsets.only(
              top: 48, left: 16, right: 16, bottom: 16),
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
                    : ListView.separated(
                        itemCount: widget.grupo.membros.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        const Color(0xFF8E76F7),
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
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: despesas.length,
            itemBuilder: (context, index) {
              final expense = despesas[index];
              return _buildExpenseCard(
                  context, expense, isDark, textScale, index);
            },
          ),
      ],
    );
  }

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
              Text(
                'Toque em "Nova despesa" para começar',
                style: TextStyle(
                  fontSize: 12 * textScale,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      label:
          'Despesa ${index + 1}: ${expense.description}, valor R\$ ${expense.value.toStringAsFixed(2)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : Colors.grey.shade200,
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
                          fontSize: 14 * textScale,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pago por: $payerName',
                        style: TextStyle(
                          fontSize: 12 * textScale,
                          color:
                              isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${expense.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14 * textScale,
                    color: const Color(0xFF8E76F7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Divisão',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12 * textScale,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            ...widget.grupo.membros.map((membro) {
              final nome = _getUserName(membro);
              if (membro == expense.payer) {
                final payerNet = expense.value - valorPorPessoa;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(nome,
                          style: TextStyle(
                              fontSize: 12 * textScale,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600)),
                      Text(
                        'R\$ ${payerNet.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12 * textScale,
                          color: Colors.green.shade600,
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
                      Text(nome,
                          style: TextStyle(
                              fontSize: 12 * textScale,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600)),
                      Text(
                        'R\$ ${valorPorPessoa.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12 * textScale,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}