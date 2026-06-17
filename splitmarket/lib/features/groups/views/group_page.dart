import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import 'group_detail_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final FocusNode _addGroupFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<GroupProvider>(context, listen: false).carregarGrupos();
    });
  }

  @override
  void dispose() {
    _addGroupFocusNode.dispose();
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

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Tela de grupos',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Semantics(
            header: true,
            label: 'Meus Grupos',
            child: Text(
              'Meus Grupos',
              style: TextStyle(
                fontSize: 18 * textScale,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Consumer<GroupProvider>(
          builder: (context, groupProvider, child) {
            if (groupProvider.carregando) {
              return Center(
                child: Semantics(
                  label: 'Carregando grupos',
                  child: const CircularProgressIndicator(),
                ),
              );
            }

            if (groupProvider.grupos.isEmpty) {
              return _buildEmptyState(context, isDark, textScale);
            }

            return Semantics(
              label: 'Lista de grupos, ${groupProvider.grupos.length} itens',
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupProvider.grupos.length,
                itemBuilder: (context, index) {
                  final grupo = groupProvider.grupos[index];
                  return _buildGroupCard(
                    context,
                    grupo,
                    index,
                    isDark,
                    textScale,
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: Semantics(
          button: true,
          label: 'Criar novo grupo',
          hint: 'Toque para criar um novo grupo',
          child: FloatingActionButton(
            focusNode: _addGroupFocusNode,
            onPressed: () => _mostrarDialogoCriarGrupo(context),
            backgroundColor: const Color(0xFF8E76F7),
            child: const Icon(Icons.add),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 2),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    double textScale,
  ) {
    return Center(
      child: Semantics(
        label: 'Nenhum grupo criado',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              excluding: true,
              child: Icon(
                Icons.group_outlined,
                size: 64 * textScale,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum grupo criado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20 * textScale,
                  ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Crie um novo grupo para começar',
              child: Text(
                'Crie um novo grupo para começar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontSize: 14 * textScale,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Criar primeiro grupo',
              hint: 'Toque para criar seu primeiro grupo',
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCriarGrupo(context),
                icon: const Icon(Icons.add),
                label: Text(
                  'Criar grupo',
                  style: TextStyle(
                    fontSize: 16 * textScale,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E76F7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD DO GRUPO - CORRIGIDO ✅
  // ============================================================
  Widget _buildGroupCard(
    BuildContext context,
    dynamic grupo,
    int index,
    bool isDark,
    double textScale,
  ) {
    return Semantics(
      container: true,
      label: 'Grupo ${index + 1}: ${grupo.nome}, ${grupo.membros.length} membros',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          onTap: () {
            _announceToTalkBack('Abrindo grupo ${grupo.nome}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailPage(grupo: grupo),
              ),
            );
          },
          // ✅ CORRIGIDO: ExcludeSemantics em vez de Semantics
          leading: ExcludeSemantics(
            excluding: true,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF8E76F7),
              child: Icon(
                Icons.group,
                color: Colors.white,
                size: 20 * textScale,
              ),
            ),
          ),
          title: Text(
            grupo.nome,
            style: TextStyle(
              fontSize: 16 * textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Semantics(
            label: '${grupo.membros.length} membros',
            child: Text(
              '${grupo.membros.length} membro(s)',
              style: TextStyle(
                fontSize: 14 * textScale,
              ),
            ),
          ),
          trailing: Semantics(
            button: true,
            label: 'Adicionar participante ao grupo ${grupo.nome}',
            hint: 'Toque para adicionar um novo membro',
            child: IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Adicionar participante',
              onPressed: () => _mostrarDialogoAdicionarParticipante(
                context,
                grupo.id,
                grupo.nome,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIÁLOGO CRIAR GRUPO
  // ============================================================
  void _mostrarDialogoCriarGrupo(BuildContext context) {
    final controller = TextEditingController();
    final FocusNode textFieldFocusNode = FocusNode();

    showDialog(
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
              controller: controller,
              focusNode: textFieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome do grupo',
                hintStyle: TextStyle(
                  fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                ),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
              onSubmitted: (_) {
                _criarGrupo(context, controller.text);
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
              child: TextButton(
                onPressed: () => _criarGrupo(context, controller.text),
                child: Text(
                  'Criar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                    fontWeight: FontWeight.bold,
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

  Future<void> _criarGrupo(BuildContext context, String nome) async {
    if (nome.trim().isEmpty) {
      _announceToTalkBack('Erro: Nome do grupo não pode estar vazio');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: Nome do grupo não pode estar vazio',
            child: const Text('Nome do grupo não pode estar vazio'),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await Provider.of<GroupProvider>(context, listen: false)
          .criarGrupo(nome.trim());
      
      if (!mounted) return;
      
      _announceToTalkBack('Grupo criado com sucesso');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Grupo criado com sucesso',
            child: const Text('Grupo criado com sucesso!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = 'Erro ao criar grupo: $e';
      _announceToTalkBack(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: errorMessage,
            child: Text(errorMessage),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // DIÁLOGO ADICIONAR PARTICIPANTE
  // ============================================================
  void _mostrarDialogoAdicionarParticipante(
    BuildContext context,
    String grupoId,
    String grupoNome,
  ) {
    final controller = TextEditingController();
    final FocusNode textFieldFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Diálogo para adicionar participante ao grupo $grupoNome',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Adicionar participante a $grupoNome',
            child: Text(
              'Adicionar participante a $grupoNome',
              style: TextStyle(
                fontSize: 18 * MediaQuery.of(context).textScaleFactor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          content: Semantics(
            textField: true,
            label: 'Email do participante',
            hint: 'Digite o email da pessoa que deseja adicionar',
            child: TextField(
              controller: controller,
              focusNode: textFieldFocusNode,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email do participante',
                hintStyle: TextStyle(
                  fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              style: TextStyle(
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
              onSubmitted: (_) {
                _adicionarParticipante(
                  context,
                  grupoId,
                  controller.text,
                );
              },
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar adição de participante',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Adição de participante cancelada');
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
              label: 'Adicionar participante',
              hint: 'Confirmar adição do novo participante',
              child: TextButton(
                onPressed: () => _adicionarParticipante(
                  context,
                  grupoId,
                  controller.text,
                ),
                child: Text(
                  'Adicionar',
                  style: TextStyle(
                    fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                    fontWeight: FontWeight.bold,
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

  Future<void> _adicionarParticipante(
    BuildContext context,
    String grupoId,
    String email,
  ) async {
    if (email.trim().isEmpty) {
      _announceToTalkBack('Erro: Email não pode estar vazio');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: Email não pode estar vazio',
            child: const Text('Email não pode estar vazio'),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _announceToTalkBack('Erro: Email inválido');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: Email inválido',
            child: const Text('Email inválido'),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await Provider.of<GroupProvider>(context, listen: false)
          .adicionarParticipante(grupoId, email.trim());
      
      if (!mounted) return;
      
      _announceToTalkBack('Participante adicionado com sucesso');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Participante adicionado com sucesso',
            child: const Text('Participante adicionado com sucesso!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = 'Erro ao adicionar participante: $e';
      _announceToTalkBack(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: errorMessage,
            child: Text(errorMessage),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}