// lib/features/auth/views/register_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/models/user_model.dart'; // Vamos criar esse arquivo

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController(); // 👈 NOVO: campo nome
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📧 Email: ${emailController.text.trim()}');
      print('🔑 Senha: ${passwordController.text.trim()}');
      print('👤 Nome: ${nameController.text.trim()}');
      
      // 1. Criar usuário no Firebase Auth
      final user = await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      print('👤 Usuário retornado: $user');
      print('📦 Tipo: ${user.runtimeType}');

      if (user == null) {
        throw Exception('Falha ao criar conta. Tente novamente.');
      }

      // 2. Pegar o UID do usuário atual
      final FirebaseAuth auth = FirebaseAuth.instance;
      final String userId = auth.currentUser!.uid;
      final String userEmail = emailController.text.trim();
      final String userName = nameController.text.trim().isEmpty 
          ? userEmail.split('@')[0] 
          : nameController.text.trim();

      // 3. Criar documento do usuário no Firestore
      final UserModel userModel = UserModel(
        id: userId,
        email: userEmail,
        name: userName,
        avatar: null, // Será atualizado depois quando o usuário adicionar foto
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // 4. Salvar no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userModel.toMap());

      print('✅ Usuário salvo no Firestore: $userName');

      // 5. Salvar dados localmente
      await PreferencesService.saveUserName(userName);
      await PreferencesService.saveUserEmail(userEmail);
      await PreferencesService.saveUserId(userId);
      await PreferencesService.saveLogin(true);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (error, stackTrace) {
      print('❌ ERRO: $error');
      print('📚 StackTrace: $stackTrace');
      
      String errorMessage = error.toString().replaceAll('Exception:', '').trim();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crie sua conta',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use um email válido e escolha uma senha segura para começar a controlar suas despesas em grupo.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    
                    // 👈 NOVO: Campo Nome
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Como você quer ser chamado?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
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
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
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
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
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
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Cadastrar', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Já tenho conta, fazer login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}