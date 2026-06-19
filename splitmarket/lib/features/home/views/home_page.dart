import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/preferences_service.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../notifications/models/debt_notification.dart';
import '../../notifications/viewmodels/notification_provider.dart';

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
  String? _photoBase64;

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, String> _memberIdToName = {};

  final FocusNode _receivableCardFocusNode = FocusNode();
  final FocusNode _payableCardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _receivableCardFocusNode.dispose();
    _payableCardFocusNode.dispose();
    super.dispose();
  }

  void _announceToTalkBack(String message) {
    if (!mounted) return;
    SemanticsService.announce(message, Directionality.of(context));
  }

  Future<void> _loadDashboardData() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    await groupProvider.carregarGrupos();

    if (groupProvider.grupos.isNotEmpty) {
      _selectedGroup = groupProvider.grupos.first;
      _currentGroup = _selectedGroup!.nome;
      _currentGroupId = _selectedGroup!.id;

      await _loadUserNameFromFirestore();
      await _loadMemberNames(_selectedGroup!.membros);
      await expenseProvider.carregarDespesasPorGrupo(_selectedGroup!.id);
    } else {
      await expenseProvider.limparDespesas();
      await _loadUserNameFromFirestore();
    }

    if (!mounted) return;

    setState(() {
      _currentGroup =
          groupProvider.grupos.isNotEmpty ? _selectedGroup!.nome : 'Sem grupo';
    });
  }

  Future<void> _loadMemberNames(List<String> memberIds) async {
    _memberIdToName.clear();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      for (final memberId in memberIds) {
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
        } else {
          _memberIdToName[memberId] = 'Desconhecido';
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar nomes dos membros: $e');
    }
  }

  Future<void> _loadUserNameFromFirestore() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        setState(() {
          _userName = 'Usuário';
          _isLoadingName = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final nome = doc.data()?['name'] ?? 'Usuário';
        final photo = doc.data()?['photoBase64'];

        if (!mounted) return;

        setState(() {
          _userName = nome;
          _photoBase64 = photo;
          _isLoadingName = false;
        });

        await PreferencesService.saveUserName(nome);
      } else {
        final email = FirebaseAuth.instance.currentUser?.email;

        if (!mounted) return;

        setState(() {
          _userName = email?.split('@')[0] ?? 'Usuário';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingName = false;
      });
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 500,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'photoBase64': base64Image,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _photoBase64 = base64Image;
      });

      _announceToTalkBack('Foto de perfil atualizada com sucesso');
    } catch (e) {
      debugPrint('Erro ao atualizar imagem de perfil: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar a foto de perfil.'),
        ),
      );
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  double _totalReceivable(
    List<ExpenseModel> expenses,
    NotificationProvider notificationProvider,
  ) {
    final receivables = _buildReceivables(expenses, notificationProvider);
    return receivables
        .where((debt) => debt.status != DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  double _totalPayable(
    List<ExpenseModel> expenses,
    NotificationProvider notificationProvider,
  ) {
    final payables = _buildPayables(expenses, notificationProvider);
    return payables
        .where((debt) => debt.status != DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  List<DebtModel> _buildReceivables(
    List<ExpenseModel> expenses,
    NotificationProvider notificationProvider,
  ) {
    final Map<String, double> aggregated = {};
    final userId = FirebaseAuth.instance.currentUser?.uid;

    for (final expense in expenses.where(
      (expense) =>
          expense.payer == _userName && expense.grupoId == _currentGroupId,
    )) {
      if (_selectedGroup != null && _selectedGroup!.membros.isNotEmpty) {
        final n = _selectedGroup!.membros.length;
        final share = expense.value / n;

        for (final memberId in _selectedGroup!.membros) {
          if (memberId == userId) continue;

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

  List<DebtModel> _buildPayables(
    List<ExpenseModel> expenses,
    NotificationProvider notificationProvider,
  ) {
    final Map<String, double> aggregated = {};

    for (final expense in expenses.where(
      (expense) =>
          expense.payer != _userName && expense.grupoId == _currentGroupId,
    )) {
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

    _announceToTalkBack(
      _showReceivables
          ? 'Mostrando valores a receber'
          : 'Ocultando valores a receber',
    );
  }

  void _togglePayables() {
    setState(() {
      _showPayables = !_showPayables;
      if (_showPayables) _showReceivables = false;
    });

    _announceToTalkBack(
      _showPayables
          ? 'Mostrando valores a pagar'
          : 'Ocultando valores a pagar',
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final TextEditingController groupNameController = TextEditingController();
    final FocusNode textFieldFocusNode = FocusNode();

    return showDialog(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Diálogo para criar novo grupo',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Novo Grupo',
            child: Text(
              'Novo Grupo',
              style: TextStyle(
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          content: Semantics(
            textField: true,
            label: 'Nome do grupo',
            hint: 'Digite o nome do novo grupo',
            child: TextField(
              controller: groupNameController,
              focusNode: textFieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ex: Viagem, Casa, Faculdade...',
                labelText: 'Nome do grupo',
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(
                  fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                ),
                labelStyle: TextStyle(
                  fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                ),
              ),
              style: TextStyle(
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
              onSubmitted: (_) async {
                final groupName = groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  await _criarGrupo(context, groupName);
                }
              },
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar criação do grupo',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Criação de grupo cancelada');
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Criar grupo',
              hint: 'Confirmar criação do novo grupo',
              child: ElevatedButton(
                onPressed: () async {
                  final groupName = groupNameController.text.trim();
                  if (groupName.isNotEmpty) {
                    await _criarGrupo(context, groupName);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E76F7),
                ),
                child: Text(
                  'Criar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      textFieldFocusNode.dispose();
      groupNameController.dispose();
    });
  }

  Future<void> _criarGrupo(BuildContext context, String groupName) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.criarGrupo(groupName);

      if (!mounted) return;

      _announceToTalkBack('Grupo $groupName criado com sucesso');
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Grupo $groupName criado com sucesso',
            child: Text('Grupo "$groupName" criado!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      await _loadDashboardData();
    } catch (e) {
      if (!mounted) return;

      _announceToTalkBack('Erro ao criar grupo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro ao criar grupo',
            child: Text('Erro ao criar grupo: $e'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showSelectGroupDialog() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (groupProvider.grupos.isEmpty) {
      _announceToTalkBack('Nenhum grupo criado. Crie um novo grupo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Nenhum grupo criado. Crie um novo grupo',
            child: const Text('Nenhum grupo criado. Crie um novo grupo!'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Diálogo para selecionar grupo',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Selecionar Grupo',
            child: Text(
              'Selecionar Grupo',
              style: TextStyle(
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Semantics(
              label: 'Lista de grupos disponíveis',
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groupProvider.grupos.length,
                itemBuilder: (context, index) {
                  final grupo = groupProvider.grupos[index];

                  return Semantics(
                    container: true,
                    label:
                        'Grupo ${index + 1}: ${grupo.nome}, ${grupo.membros.length} membros',
                    child: ListTile(
                      leading: ExcludeSemantics(
                        excluding: true,
                        child: const Icon(
                          Icons.group,
                          color: Color(0xFF8E76F7),
                        ),
                      ),
                      title: Text(
                        grupo.nome,
                        style: TextStyle(
                          fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                        ),
                      ),
                      subtitle: Text(
                        '${grupo.membros.length} membros',
                        style: TextStyle(
                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                        ),
                      ),
                      onTap: () async {
                        _announceToTalkBack('Selecionando grupo ${grupo.nome}');

                        setState(() {
                          _selectedGroup = grupo;
                          _currentGroup = grupo.nome;
                          _currentGroupId = grupo.id;
                        });

                        await _loadMemberNames(grupo.membros);
                        await context
                            .read<ExpenseProvider>()
                            .carregarDespesasPorGrupo(grupo.id);

                        if (!mounted) return;

                        Navigator.pop(context);
                        _announceToTalkBack('Grupo alterado para $_currentGroup');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Semantics(
                              label: 'Grupo alterado para $_currentGroup',
                              child: Text('Grupo alterado para "$_currentGroup"'),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Fechar',
              hint: 'Fechar diálogo de seleção de grupo',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Seleção de grupo cancelada');
                  Navigator.pop(context);
                },
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required bool active,
    required VoidCallback onTap,
    required Color accentColor,
    required FocusNode? focusNode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Semantics(
      button: true,
      label: '$title: R\$ ${value.toStringAsFixed(2)}',
      hint: active
          ? 'Toque para ocultar os detalhes'
          : 'Toque para ver os detalhes',
      child: GestureDetector(
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
              color: active
                  ? accentColor
                  : (isDark
                      ? const Color(0xFF3D3D3D)
                      : Colors.grey.shade200),
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
                  fontSize: (isMobile ? 14 : 16) * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: (isMobile ? 20 : 28) * textScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
    final textScale = MediaQuery.of(context).textScaleFactor;

    if (items.isEmpty) {
      return Semantics(
        label: '$title: Nenhum registro encontrado',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Nenhum registro encontrado.',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: (isMobile ? 13 : 14) * textScale,
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: '$title, ${items.length} itens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Semantics(
            header: true,
            label: title,
            child: Text(
              title,
              style: TextStyle(
                fontSize: (isMobile ? 16 : 18) * textScale,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
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
              return _buildDebtItem(
                debt,
                index,
                accentColor,
                isDark,
                isMobile,
                textScale,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(
    DebtModel debt,
    int index,
    Color accentColor,
    bool isDark,
    bool isMobile,
    double textScale,
  ) {
    return Semantics(
      container: true,
      label:
          'Dívida ${index + 1}: ${debt.participant}, R\$ ${debt.amount.toStringAsFixed(2)}, ${debt.statusLabel}',
      child: Container(
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
                      Semantics(
                        label: 'Participante: ${debt.participant}',
                        child: Text(
                          debt.participant,
                          style: TextStyle(
                            fontSize: (isMobile ? 14 : 15) * textScale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        label: debt.description,
                        child: Text(
                          debt.description,
                          style: TextStyle(
                            fontSize: (isMobile ? 12 : 13) * textScale,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Valor: R\$ ${debt.amount.toStringAsFixed(2)}',
                  child: Text(
                    'R\$ ${debt.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: (isMobile ? 14 : 16) * textScale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Semantics(
                  label: 'Status: ${debt.statusLabel}',
                  child: Container(
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
                        fontSize: 12 * textScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (debt.status == DebtStatus.pending)
                  Semantics(
                    button: true,
                    label: accentColor == Colors.green
                        ? 'Solicitar pagamento para ${debt.participant}'
                        : 'Pagar dívida para ${debt.participant}',
                    hint: accentColor == Colors.green
                        ? 'Toque para solicitar o pagamento'
                        : 'Toque para pagar esta dívida',
                    child: ElevatedButton(
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
                      child: Text(
                        accentColor == Colors.green
                            ? 'Solicitar pagamento'
                            : 'Pagar',
                        style: TextStyle(fontSize: 12 * textScale),
                      ),
                    ),
                  )
                else if (debt.status == DebtStatus.awaitingConfirmation &&
                    accentColor == Colors.green)
                  Semantics(
                    button: true,
                    label: 'Confirmar recebimento de ${debt.participant}',
                    hint: 'Toque para confirmar que recebeu o pagamento',
                    child: ElevatedButton(
                      onPressed: () => _openConfirmReceiptDialog(debt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Confirmar recebimento',
                        style: TextStyle(fontSize: 12 * textScale),
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: debt.status == DebtStatus.awaitingConfirmation
                        ? 'Aguardando confirmação'
                        : 'Comprovante registrado',
                    child: Text(
                      debt.status == DebtStatus.awaitingConfirmation
                          ? 'Aguardando confirmação'
                          : 'Comprovante registrado',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12 * textScale,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
          builder: (context, setLocalState) {
            return Semantics(
              container: true,
              label: 'Diálogo para pagar dívida',
              child: AlertDialog(
                title: Semantics(
                  header: true,
                  label: 'Pagar dívida',
                  child: Text(
                    'Pagar dívida',
                    style: TextStyle(
                      fontSize: 20 * MediaQuery.of(context).textScaleFactor,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          label:
                              'Você deve R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}',
                          child: Text(
                            'Você deve R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}.',
                            style: TextStyle(
                              fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          textField: true,
                          label: 'Observação',
                          hint: 'Digite uma observação opcional',
                          child: TextFormField(
                            initialValue: observation,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Observação (opcional)',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                            ),
                            onChanged: (value) => observation = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (proofFile != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                label:
                                    'Arquivo selecionado: ${proofFile!.path.split('/').last}',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_file,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        proofFile!.path.split('/').last,
                                        style: TextStyle(
                                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setLocalState(() {
                                          proofFile = null;
                                        });
                                        _announceToTalkBack('Arquivo removido');
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_isImageFile(proofFile!))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    proofFile!,
                                    fit: BoxFit.cover,
                                    height: 120,
                                    width: double.infinity,
                                  ),
                                ),
                              if (_isPdfFile(proofFile!))
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.picture_as_pdf,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '📄 ${proofFile!.path.split('/').last}',
                                        style: TextStyle(
                                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Tirar foto',
                                hint:
                                    'Toque para abrir a câmera e tirar uma foto do comprovante',
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await _imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 70,
                                    );

                                    if (picked != null) {
                                      setLocalState(() {
                                        proofFile = File(picked.path);
                                      });
                                      _announceToTalkBack(
                                        'Foto capturada com sucesso',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: Text(
                                    'Câmera',
                                    style: TextStyle(
                                      fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Selecionar arquivo',
                                hint:
                                    'Toque para selecionar um arquivo da galeria',
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await _imagePicker.pickMedia();
                                    if (picked != null) {
                                      setLocalState(() {
                                        proofFile = File(picked.path);
                                      });
                                      _announceToTalkBack(
                                        'Arquivo selecionado: ${picked.path.split('/').last}',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.folder_open, size: 18),
                                  label: Text(
                                    'Arquivo',
                                    style: TextStyle(
                                      fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label:
                              'Aceita imagens, PDF e outros formatos de arquivo',
                          child: Text(
                            '📎 Aceita imagens, PDF e outros formatos',
                            style: TextStyle(
                              fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Semantics(
                    button: true,
                    label: 'Cancelar',
                    hint: 'Cancelar pagamento',
                    child: TextButton(
                      onPressed: () {
                        _announceToTalkBack('Pagamento cancelado');
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Enviar comprovante',
                    hint:
                        'Enviar comprovante para confirmar o pagamento',
                    child: ElevatedButton(
                      onPressed: () {
                        if (proofFile == null) {
                          _announceToTalkBack('Anexe um comprovante');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Semantics(
                                label:
                                    'Anexe um comprovante para concluir o pagamento',
                                child: const Text(
                                  'Anexe um comprovante para concluir o pagamento.',
                                ),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        final filePath = proofFile!.path;

                        context.read<NotificationProvider>().addNotification(
                              DebtNotification(
                                sender: _userName,
                                receiver: debt.participant,
                                amount: debt.amount,
                                description: debt.description,
                                status: DebtStatus.awaitingConfirmation,
                                proofImagePath: filePath,
                              ),
                            );

                        Navigator.of(context).pop();

                        _announceToTalkBack(
                          'Pagamento registrado. Aguardando confirmação de ${debt.participant}',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Semantics(
                              label:
                                  'Pagamento registrado. Aguardando confirmação de ${debt.participant}',
                              child: Text(
                                'Pagamento de R\$ ${debt.amount.toStringAsFixed(2)} registrado. ${debt.participant} receberá a notificação para confirmar.',
                              ),
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      child: Text(
                        'Enviar comprovante',
                        style: TextStyle(
                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
    ];
    return imageExtensions.contains(extension);
  }

  bool _isPdfFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  Future<void> _openConfirmReceiptDialog(DebtModel debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Confirmar recebimento',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Confirmar recebimento',
            child: Text(
              'Confirmar recebimento',
              style: TextStyle(
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          content: Semantics(
            label:
                'Você recebeu R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.participant}?',
            child: Text(
              'Você recebeu R\$ ${debt.amount.toStringAsFixed(2)} de ${debt.participant}?',
              style: TextStyle(
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar confirmação',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Confirmação cancelada');
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Confirmar recebimento',
              hint: 'Confirmar que você recebeu o pagamento',
              child: ElevatedButton(
                onPressed: () {
                  _announceToTalkBack('Recebimento confirmado');
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    context.read<NotificationProvider>().confirmNotificationFor(
          sender: debt.participant,
          receiver: _userName,
          amount: debt.amount,
        );

    _announceToTalkBack(
      'Recebimento de R\$ ${debt.amount.toStringAsFixed(2)} confirmado',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label:
              'Recebimento de R\$ ${debt.amount.toStringAsFixed(2)} confirmado',
          child: Text(
            'Recebimento de R\$ ${debt.amount.toStringAsFixed(2)} confirmado.',
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openRequestPaymentDialog(DebtModel debt) async {
    String message = '';
    final FocusNode textFieldFocusNode = FocusNode();

    await showDialog(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Solicitar pagamento',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Solicitar pagamento',
            child: Text(
              'Solicitar pagamento',
              style: TextStyle(
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label:
                    'Enviar solicitação de R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}',
                child: Text(
                  'Enviar solicitação de R\$ ${debt.amount.toStringAsFixed(2)} para ${debt.participant}?',
                  style: TextStyle(
                    fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                textField: true,
                label: 'Mensagem',
                hint: 'Digite uma mensagem opcional',
                child: TextField(
                  focusNode: textFieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Mensagem (opcional)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(
                      fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                  ),
                  onChanged: (v) => message = v,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar solicitação',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Solicitação cancelada');
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Enviar solicitação',
              hint: 'Enviar solicitação de pagamento',
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _announceToTalkBack(
                    'Solicitação enviada para ${debt.participant}',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Semantics(
                        label:
                            'Solicitação enviada para ${debt.participant}',
                        child: Text(
                          'Solicitação enviada para ${debt.participant}.',
                        ),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Text(
                  'Enviar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      textFieldFocusNode.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final expenses = expenseProvider.despesas;

    final totalReceivable = _totalReceivable(expenses, notificationProvider);
    final totalPayable = _totalPayable(expenses, notificationProvider);
    final receivables = _buildReceivables(expenses, notificationProvider);
    final payables = _buildPayables(expenses, notificationProvider);

    return Semantics(
      container: true,
      label: 'Página inicial',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: expenseProvider.carregando || _isLoadingName
            ? Center(
                child: Semantics(
                  label: 'Carregando dados',
                  child: const CircularProgressIndicator(),
                ),
              )
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
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showProfileImageOptions,
                              child: Semantics(
                                button: true,
                                label: 'Foto de perfil. Toque para alterar',
                                child: CircleAvatar(
                                  radius: isMobile ? 42 : 55,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: _photoBase64 != null &&
                                          _photoBase64!.isNotEmpty
                                      ? MemoryImage(
                                          base64Decode(_photoBase64!),
                                        )
                                      : null,
                                  child: _photoBase64 == null ||
                                          _photoBase64!.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: isMobile ? 42 : 55,
                                          color: Colors.grey.shade700,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              header: true,
                              label: '$_greeting, $_userName',
                              child: Text(
                                '$_greeting, $_userName',
                                style: TextStyle(
                                  fontSize: (isMobile ? 24 : 32) * textScale,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Veja como está sua posição no grupo hoje.',
                              style: TextStyle(
                                fontSize: (isMobile ? 14 : 16) * textScale,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'A receber',
                              value: totalReceivable,
                              active: _showReceivables,
                              accentColor: Colors.green,
                              onTap: _toggleReceivables,
                              focusNode: _receivableCardFocusNode,
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
                              focusNode: _payableCardFocusNode,
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
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                        fontSize:
                                            (isMobile ? 13 : 14) * textScale,
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 0),
      ),
    );
  }
}