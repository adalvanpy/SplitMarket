// lib/features/auth/views/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 🎯 Focus nodes para navegação por teclado/TalkBack
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _registerButtonFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _registerButtonFocusNode.dispose();
    _loginButtonFocusNode.dispose();
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

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      _announceToTalkBack('Por favor, corrija os erros no formulário');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📧 Email: ${emailController.text.trim()}');
      debugPrint('🔑 Senha: ${passwordController.text.trim()}');
      debugPrint('👤 Nome: ${nameController.text.trim()}');
      
      final user = await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      debugPrint('👤 Usuário retornado: $user');
      debugPrint('📦 Tipo: ${user.runtimeType}');

      if (user == null) {
        throw Exception('Falha ao criar conta. Tente novamente.');
      }

      final FirebaseAuth auth = FirebaseAuth.instance;
      final String userId = auth.currentUser!.uid;
      final String userEmail = emailController.text.trim();
      final String userName = nameController.text.trim().isEmpty 
          ? userEmail.split('@')[0] 
          : nameController.text.trim();

      final UserModel userModel = UserModel(
        id: userId,
        email: userEmail,
        name: userName,
        avatar: null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userModel.toMap());

      debugPrint('✅ Usuário salvo no Firestore: $userName');

      await PreferencesService.saveUserName(userName);
      await PreferencesService.saveUserEmail(userEmail);
      await PreferencesService.saveUserId(userId);
      await PreferencesService.saveLogin(true);

      if (!mounted) return;
      
      // 🗣️ Anúncio de sucesso
      _announceToTalkBack('Conta criada com sucesso! Bem-vindo, $userName');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Conta criada com sucesso! Bem-vindo, $userName',
            child: Text('Conta criada com sucesso!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (error, stackTrace) {
      debugPrint('❌ ERRO: $error');
      debugPrint('📚 StackTrace: $stackTrace');
      
      String errorMessage = error.toString().replaceAll('Exception:', '').trim();
      
      // 🗣️ Anúncio de erro
      _announceToTalkBack('Erro: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: $errorMessage',
            child: Text(errorMessage),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
Widget build(BuildContext context) {
  final textScale = MediaQuery.of(context).textScaleFactor;

  return Semantics(
    container: true,
    label: 'Tela de cadastro de usuário',
    child: Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Tela de cadastro',
          child: const Text('Cadastro'),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Crie sua conta - formulário de cadastro',
                      child: Text(
                        'Crie sua conta',
                        style: TextStyle(
                          fontSize: 28 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label:
                          'Use um email válido e escolha uma senha segura para começar a controlar suas despesas em grupo.',
                      child: Text(
                        'Use um email válido e escolha uma senha segura para começar a controlar suas despesas em grupo.',
                        style: TextStyle(
                          fontSize: 16 * textScale,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildNameField(textScale),
                    const SizedBox(height: 16),
                    _buildEmailField(textScale),
                    const SizedBox(height: 16),
                    _buildPasswordField(textScale),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(textScale),
                    const SizedBox(height: 32),
                    _buildRegisterButton(textScale),
                    const SizedBox(height: 16),
                    _buildLoginButton(textScale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
  // ============================================================
  // COMPONENTES ACESSÍVEIS
  // ============================================================

  Widget _buildNameField(double textScale) {
    return Semantics(
      textField: true,
      label: 'Nome',
      hint: 'Como você quer ser chamado?',
      enabled: !_isLoading,
      child: TextFormField(
        controller: nameController,
        focusNode: _nameFocusNode,
        textCapitalization: TextCapitalization.words,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: 'Nome',
          hintText: 'Como você quer ser chamado?',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person_outline),
          labelStyle: TextStyle(
            fontSize: 16 * textScale,
          ),
          hintStyle: TextStyle(
            fontSize: 14 * textScale,
            color: Colors.grey[600],
          ),
          errorStyle: TextStyle(
            fontSize: 14 * textScale,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe seu nome';
          }
          if (value.trim().length < 3) {
            return 'Nome deve ter pelo menos 3 caracteres';
          }
          return null;
        },
        onEditingComplete: () {
          _nameFocusNode.unfocus();
          FocusScope.of(context).requestFocus(_emailFocusNode);
        },
      ),
    );
  }

  Widget _buildEmailField(double textScale) {
    return Semantics(
      textField: true,
      label: 'Email',
      hint: 'Digite seu endereço de email',
      enabled: !_isLoading,
      child: TextFormField(
        controller: emailController,
        focusNode: _emailFocusNode,
        enabled: !_isLoading,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'exemplo@email.com',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.email_outlined),
          labelStyle: TextStyle(
            fontSize: 16 * textScale,
          ),
          hintStyle: TextStyle(
            fontSize: 14 * textScale,
            color: Colors.grey[600],
          ),
          errorStyle: TextStyle(
            fontSize: 14 * textScale,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe seu email';
          }
          if (!value.contains('@') || !value.contains('.')) {
            return 'Informe um email válido';
          }
          return null;
        },
        onEditingComplete: () {
          _emailFocusNode.unfocus();
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
      ),
    );
  }

  Widget _buildPasswordField(double textScale) {
    return Semantics(
      textField: true,
      label: 'Senha',
      hint: 'Digite sua senha com pelo menos 6 caracteres',
      enabled: !_isLoading,
      child: TextFormField(
        controller: passwordController,
        focusNode: _passwordFocusNode,
        enabled: !_isLoading,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'Senha',
          hintText: 'Mínimo 6 caracteres',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
          labelStyle: TextStyle(
            fontSize: 16 * textScale,
          ),
          hintStyle: TextStyle(
            fontSize: 14 * textScale,
            color: Colors.grey[600],
          ),
          errorStyle: TextStyle(
            fontSize: 14 * textScale,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Informe a senha';
          }
          if (value.length < 6) {
            return 'A senha deve ter ao menos 6 caracteres';
          }
          return null;
        },
        onEditingComplete: () {
          _passwordFocusNode.unfocus();
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField(double textScale) {
    return Semantics(
      textField: true,
      label: 'Confirmar senha',
      hint: 'Digite a senha novamente para confirmar',
      enabled: !_isLoading,
      child: TextFormField(
        controller: confirmPasswordController,
        focusNode: _confirmPasswordFocusNode,
        enabled: !_isLoading,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'Confirmar senha',
          hintText: 'Digite a senha novamente',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
          labelStyle: TextStyle(
            fontSize: 16 * textScale,
          ),
          hintStyle: TextStyle(
            fontSize: 14 * textScale,
            color: Colors.grey[600],
          ),
          errorStyle: TextStyle(
            fontSize: 14 * textScale,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Confirme a senha';
          }
          if (value != passwordController.text) {
            return 'As senhas não coincidem';
          }
          return null;
        },
        onEditingComplete: () {
          _confirmPasswordFocusNode.unfocus();
          FocusScope.of(context).requestFocus(_registerButtonFocusNode);
        },
      ),
    );
  }

  Widget _buildRegisterButton(double textScale) {
    return Semantics(
      button: true,
      label: _isLoading ? 'Cadastrando...' : 'Cadastrar',
      hint: 'Toque para criar sua conta',
      enabled: !_isLoading,
      child: ElevatedButton(
        focusNode: _registerButtonFocusNode,
        onPressed: _isLoading ? null : register,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? Semantics(
                label: 'Carregando, aguarde',
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              )
            : Text(
                'Cadastrar',
                style: TextStyle(
                  fontSize: 16 * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginButton(double textScale) {
    return Semantics(
      button: true,
      label: 'Já tenho conta, fazer login',
      hint: 'Toque para voltar à tela de login',
      enabled: !_isLoading,
      child: TextButton(
        focusNode: _loginButtonFocusNode,
        onPressed: _isLoading 
            ? null 
            : () {
                _announceToTalkBack('Voltando para tela de login');
                Navigator.pop(context);
              },
        child: Text(
          'Já tenho conta, fazer login',
          style: TextStyle(
            fontSize: 16 * textScale,
          ),
        ),
      ),
    );
  }
}