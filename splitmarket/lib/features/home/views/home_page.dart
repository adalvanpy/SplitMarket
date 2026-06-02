import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/preferences_service.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../notifications/models/debt_notification.dart';
import '../../notifications/viewmodels/notification_provider.dart';
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
  String? _currentGroupId;
  GroupModel? _selectedGroup;
  bool _showReceivables = false;
  bool _showPayables = false;
  bool _isLoadingName = true;
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, String> _memberIdToName = {}; // Map UID -> name

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

    await groupProvider.carregarGrupos();

    if (groupProvider.grupos.isNotEmpty) {
      _selectedGroup = groupProvider.grupos.first;
      _currentGroup = _selectedGroup!.nome;
      _currentGroupId = _selectedGroup!.id;
      await _loadMemberNames(_selectedGroup!.membros);
      await expenseProvider.carregarDespesasPorGrupo(_selectedGroup!.id);
    } else {
      await expenseProvider.limparDespesas();
    }

    await _loadUserNameFromFirestore();

    if (!mounted) return;

    setState(() {
      if (groupProvider.grupos.isNotEmpty) {
        _currentGroup = _selectedGroup!.nome;
      } else {
        _currentGroup = 'Sem grupo';
      }
    });
  }

  Future<void> _loadMemberNames(List<String> memberIds) async {
    _memberIdToName.clear();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      for (var memberId in memberIds) {
        if (memberId == userId) {
          _memberIdToName[memberId] = _userName;
          continue;
        }
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        if (doc.exists) {
          final name = doc.data()?['name'] ?? 'Desconhecido';
          _memberIdToName[memberId] = name;
        }
      }
    } catch (e) {
      print('Erro ao carregar nomes dos membros: $e');
    }
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

  double _totalReceivable(List<ExpenseModel> expenses, NotificationProvider notificationProvider) {
    final receivables = _buildReceivables(expenses, notificationProvider);
    return receivables
        .where((debt) => debt.status != DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  double _totalPayable(List<ExpenseModel> expenses, NotificationProvider notificationProvider) {
    final payables = _buildPayables(expenses, notificationProvider);
    return payables
        .where((debt) => debt.status != DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  List<DebtModel> _buildReceivables(List<ExpenseModel> expenses, NotificationProvider notificationProvider) {
    final Map<String, double> aggregated = {};
    final userId = FirebaseAuth.instance.currentUser?.uid;

    for (var expense in expenses.where((expense) => expense.payer == _userName && expense.grupoId == _currentGroupId)) {
      if (_selectedGroup != null && _selectedGroup!.membros.isNotEmpty) {
        final n = _selectedGroup!.membros.length;
        final share = expense.value / n;
        for (var memberId in _selectedGroup!.membros) {
          if (memberId == userId) continue; // Skip current user
          final memberName = _memberIdToName[memberId] ?? 'Desconhecido';
          aggregated[memberName] = (aggregated[memberName] ?? 0) + share;
        }
      }
    }

    return aggregated.entries.map((entry) {
      final existing = notificationProvider.getNotificationFor(
        sender: entry.key,
        receiver: _userName,
        amount: entry.value,
      );
      final status = existing?.status ?? DebtStatus.pending;
      return DebtModel(
        participant: entry.key,
        amount: entry.value,
        description: 'Devido por ${entry.key}',
        status: status,
        proofImagePath: existing?.proofImagePath,
      );
    }).toList();
  }

  List<DebtModel> _buildPayables(List<ExpenseModel> expenses, NotificationProvider notificationProvider) {
    final Map<String, double> aggregated = {};

    for (var expense in expenses.where((expense) => expense.payer != _userName && expense.grupoId == _currentGroupId)) {
      double share = expense.value;
      if (_selectedGroup != null && _selectedGroup!.membros.isNotEmpty) {
        final n = _selectedGroup!.membros.length;
        share = expense.value / n;
      }
      aggregated[expense.payer] = (aggregated[expense.payer] ?? 0) + share;
    }

    return aggregated.entries.map((entry) {
      final existing = notificationProvider.getNotificationFor(
        sender: _userName,
        receiver: entry.key,
        amount: entry.value,
      );
      final status = existing?.status ?? DebtStatus.pending;
      return DebtModel(
        participant: entry.key,
        amount: entry.value,
        description: 'Total devido a ${entry.key}',
        status: status,
        proofImagePath: existing?.proofImagePath,
      );
    }).toList();
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
                onTap: () async {
                  setState(() {
                    _selectedGroup = grupo;
                    _currentGroup = grupo.nome;
                    _currentGroupId = grupo.id;
                  });

                  await _loadMemberNames(grupo.membros);
                  await context.read<ExpenseProvider>().carregarDespesasPorGrupo(grupo.id);

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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: debt.status == DebtStatus.paid
                              ? Colors.green.withOpacity(0.14)
                              : Colors.orange.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          debt.statusLabel,
                          style: TextStyle(
                            color: debt.status == DebtStatus.paid
                                ? Colors.green
                                : Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (debt.status == DebtStatus.pending)
                        ElevatedButton(
                          onPressed: accentColor == Colors.green
                              ? () => _openRequestPaymentDialog(debt)
                              : () => _openDebtPaymentDialog(debt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: Text(accentColor == Colors.green ? 'Solicitar pagamento' : 'Pagar'),
                        )
                      else if (debt.status == DebtStatus.awaitingConfirmation && accentColor == Colors.green)
                        ElevatedButton(
                          onPressed: () => _openConfirmReceiptDialog(debt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Confirmar recebimento'),
                        )
                      else
                        Text(
                          debt.status == DebtStatus.awaitingConfirmation
                              ? 'Aguardando confirmação'
                              : 'Comprovante registrado',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openDebtPaymentDialog(DebtModel debt) async {
    File? proofFile;
    String observation = '';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pagar dívida'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Você deve R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}.'),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: observation,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observação (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => observation = value,
                      ),
                      const SizedBox(height: 16),
                      if (proofFile != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Comprovante'),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                proofFile!,
                                fit: BoxFit.cover,
                                height: 160,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await _imagePicker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 70,
                          );
                          if (picked != null) {
                            setState(() {
                              proofFile = File(picked.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tirar foto do comprovante'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (proofFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Anexe uma foto do comprovante para concluir o pagamento.'),
                        ),
                      );
                      return;
                    }

                    context.read<NotificationProvider>().addNotification(
                      DebtNotification(
                        sender: _userName,
                        receiver: debt.participant,
                        amount: debt.amount,
                        description: debt.description,
                        status: DebtStatus.awaitingConfirmation,
                        proofImagePath: proofFile!.path,
                      ),
                    );

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pagamento de R\$ ${debt.amount.toStringAsFixed(2)} registrado. ${debt.participant} receberá a notificação para confirmar.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Enviar comprovante'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openConfirmReceiptDialog(DebtModel debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar recebimento'),
          content: Text('Você recebeu R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.participant}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    context.read<NotificationProvider>().confirmNotificationFor(
      sender: debt.participant,
      receiver: _userName,
      amount: debt.amount,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recebimento de R\$ ${debt.amount.toStringAsFixed(2)} confirmado.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openRequestPaymentDialog(DebtModel debt) async {
    String message = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitar pagamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enviar solicitação de R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}?'),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mensagem (opcional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => message = v,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Solicitação enviada para ${debt.participant}.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final expenses = expenseProvider.despesas;
    final totalReceivable = _totalReceivable(expenses, notificationProvider);
    final totalPayable = _totalPayable(expenses, notificationProvider);
    final receivables = _buildReceivables(expenses, notificationProvider);
    final payables = _buildPayables(expenses, notificationProvider);
    final awaitingReceivables = receivables
        .where((debt) => debt.status == DebtStatus.awaitingConfirmation)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: expenseProvider.carregando || _isLoadingName
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  isMobile ? 40 : 52,
                  isMobile ? 16 : 32,
                  isMobile ? 20 : 32,
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
                    if (awaitingReceivables.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 14 : 16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.yellow.shade700),
                        ),
                        child: Text(
                          'Você tem ${awaitingReceivables.length} comprovante(s) aguardando validação. Confirme o recebimento para registrar como pago.',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Lista de dívidas pendentes do grupo atual (substitui o card de grupo)
                    Builder(
                      builder: (context) {
                        if (_currentGroupId == null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Nenhum grupo selecionado.',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          );
                        }

                        final pendingDebts = _buildPayables(expenses, notificationProvider)
                            .where((d) => d.status == DebtStatus.pending)
                            .toList();
                        final paidDebts = _buildPayables(expenses, notificationProvider)
                            .where((d) => d.status == DebtStatus.paid)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailList(
                              title: 'Dívidas pendentes — $_currentGroup',
                              items: pendingDebts,
                              accentColor: Colors.red,
                            ),
                            if (paidDebts.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDetailList(
                                title: 'Dívidas pagas — $_currentGroup',
                                items: paidDebts,
                                accentColor: Colors.green,
                              ),
                            ],
                          ],
                        );
                      },
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