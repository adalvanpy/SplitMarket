// lib/features/profile/views/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🎯 Focus nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();
  final FocusNode _cancelButtonFocusNode = FocusNode();
  final FocusNode _editButtonFocusNode = FocusNode();
  final FocusNode _logoutButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocusNode.dispose();
    _saveButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _editButtonFocusNode.dispose();
    _logoutButtonFocusNode.dispose();
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      debugPrint('🟡 User ID atual: $userId');
      
      if (userId == null) {
        debugPrint('❌ Usuário não está logado');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      debugPrint('🟡 Buscando documento do usuário no Firestore...');
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout ao conectar com Firestore');
            },
          );
      
      debugPrint('📄 Documento existe? ${doc.exists}');
      
      if (doc.exists) {
        debugPrint('✅ Dados encontrados: ${doc.data()}');
        _user = UserModel.fromMap(doc.id, doc.data()!);
        _nameController.text = _user?.name ?? '';
        _emailController.text = _user?.email ?? '';
      } else {
        debugPrint('⚠️ Documento não existe. Criando novo...');
        final user = _auth.currentUser;
        if (user != null) {
          final newUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.email?.split('@')[0] ?? 'Usuário',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          
          _user = newUser;
          _nameController.text = _user!.name;
          _emailController.text = _user!.email;
          debugPrint('✅ Usuário criado no Firestore');
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException: ${e.code} - ${e.message}');
      _errorMessage = 'Erro do Firebase: ${e.message}';
      
      _announceToTalkBack('Erro ao carregar perfil: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: ${e.message}',
            child: Text('Erro: ${e.message}'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('❌ Erro geral: $e');
      _errorMessage = 'Erro ao carregar perfil: $e';
      
      _announceToTalkBack('Erro ao carregar perfil');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro ao carregar perfil: $e',
            child: Text('Erro ao carregar perfil: $e'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newName = _nameController.text.trim();
      
      if (newName.isEmpty) {
        _announceToTalkBack('Nome não pode estar vazio');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              label: 'Nome não pode estar vazio',
              child: const Text('Nome não pode estar vazio'),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      await _firestore
          .collection('users')
          .doc(_user!.id)
          .update({
            'name': newName,
            'lastLogin': DateTime.now().toIso8601String(),
          });
      
      _user = _user!.copyWith(name: newName, lastLogin: DateTime.now());
      await PreferencesService.saveUserName(newName);
      
      setState(() => _isEditing = false);
      
      _announceToTalkBack('Perfil atualizado com sucesso');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Perfil atualizado com sucesso',
            child: const Text('Perfil atualizado com sucesso!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _announceToTalkBack('Erro ao salvar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro ao salvar: $e',
            child: Text('Erro ao salvar: $e'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Semantics(
        container: true,
        label: 'Diálogo de confirmação de saída',
        child: AlertDialog(
          title: Semantics(
            header: true,
            label: 'Sair da conta',
            child: Text(
              'Sair',
              style: TextStyle(
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          content: Semantics(
            label: 'Tem certeza que deseja sair da sua conta?',
            child: Text(
              'Tem certeza que deseja sair da sua conta?',
              style: TextStyle(
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cancelar saída da conta',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Saída cancelada');
                  Navigator.pop(context, false);
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
              label: 'Sair da conta',
              hint: 'Confirmar saída da conta',
              child: TextButton(
                onPressed: () {
                  _announceToTalkBack('Confirmando saída da conta');
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(
                  'Sair',
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
    );
    
    if (confirm == true) {
      _announceToTalkBack('Saindo da conta');
      await _authService.signOut();
      await PreferencesService.clearUserData();
      
      context.read<GroupProvider>().limparGrupos();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Tela de perfil do usuário',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // ============================================
            // Cabeçalho
            // ============================================
            Semantics(
              label: 'Cabeçalho - Meu Perfil',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 50, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8E76F7), Color(0xFFB993F9)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Row(
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      header: true,
                      label: 'Meu Perfil - título da página',
                      child: Text(
                        'Meu Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!_isEditing && !_isLoading)
                      Semantics(
                        button: true,
                        label: 'Editar perfil',
                        hint: 'Toque para editar suas informações',
                        child: IconButton(
                          focusNode: _editButtonFocusNode,
                          onPressed: () {
                            _announceToTalkBack('Modo de edição ativado');
                            setState(() => _isEditing = true);
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // ============================================
            // Conteúdo
            // ============================================
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Semantics(
                        label: 'Carregando dados do perfil',
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget(textScale)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _buildAvatar(textScale),
                              const SizedBox(height: 32),
                              _buildInfoCard(textScale),
                              const SizedBox(height: 24),
                              _buildLogoutButton(textScale),
                            ],
                          ),
                        ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 3),
      ),
    );
  }

  // ============================================================
  // WIDGET DE ERRO
  // ============================================================
  Widget _buildErrorWidget(double textScale) {
    return Center(
      child: Semantics(
        label: 'Erro ao carregar perfil',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              excluding: true,
              child: Icon(
                Icons.error_outline,
                size: 64 * textScale,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * textScale,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Tentar novamente',
              hint: 'Toque para recarregar os dados do perfil',
              child: ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E76F7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize: 16 * textScale,
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
  // AVATAR
  // ============================================================
  Widget _buildAvatar(double textScale) {
    return Semantics(
      label: 'Avatar do usuário',
      child: Container(
        width: 120 * textScale,
        height: 120 * textScale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E76F7), Color(0xFFB993F9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildAvatarInitials(textScale),
        ),
      ),
    );
  }

  Widget _buildAvatarInitials(double textScale) {
    final String initials = _user?.name.isNotEmpty == true
        ? _user!.name[0].toUpperCase()
        : '?';
    
    return Container(
      color: Colors.white.withOpacity(0.3),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 48 * textScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE INFORMAÇÕES
  // ============================================================
  Widget _buildInfoCard(double textScale) {
    return Semantics(
      container: true,
      label: 'Informações Pessoais',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  excluding: true,
                  child: const Icon(Icons.person_outline, color: Color(0xFF8E76F7)),
                ),
                const SizedBox(width: 8),
                Semantics(
                  header: true,
                  label: 'Informações Pessoais',
                  child: Text(
                    'Informações Pessoais',
                    style: TextStyle(
                      fontSize: 18 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            if (_isEditing) ...[
              // ✏️ Modo de edição
              Semantics(
                textField: true,
                label: 'Nome',
                hint: 'Digite seu nome',
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(
                      fontSize: 16 * textScale,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14 * textScale,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16 * textScale,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                textField: true,
                label: 'Email',
                enabled: false,
                child: TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(
                      fontSize: 16 * textScale,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16 * textScale,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Salvar alterações',
                      hint: 'Toque para salvar as alterações do perfil',
                      child: ElevatedButton(
                        focusNode: _saveButtonFocusNode,
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E76F7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 16 * textScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Cancelar edição',
                      hint: 'Toque para cancelar as alterações',
                      child: OutlinedButton(
                        focusNode: _cancelButtonFocusNode,
                        onPressed: () {
                          _announceToTalkBack('Edição cancelada');
                          _nameController.text = _user?.name ?? '';
                          setState(() => _isEditing = false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16 * textScale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 👤 Modo de visualização
              _buildInfoRow(
                Icons.person_outline,
                'Nome',
                _user?.name ?? '---',
                textScale,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.email_outlined,
                'Email',
                _user?.email ?? '---',
                textScale,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today,
                'Membro desde',
                _user?.createdAt != null
                    ? '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'
                    : '---',
                textScale,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LINHA DE INFORMAÇÃO
  // ============================================================
  Widget _buildInfoRow(IconData icon, String label, String value, double textScale) {
    return Row(
      children: [
        ExcludeSemantics(
          excluding: true,
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14 * textScale,
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: '$label: $value',
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14 * textScale,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTÃO SAIR
  // ============================================================
  Widget _buildLogoutButton(double textScale) {
    return Semantics(
      button: true,
      label: 'Sair da conta',
      hint: 'Toque para sair da sua conta',
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton.icon(
          focusNode: _logoutButtonFocusNode,
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            'Sair da Conta',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16 * textScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }
}