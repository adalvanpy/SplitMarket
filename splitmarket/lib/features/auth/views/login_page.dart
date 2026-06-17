import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../shared/widgets/responsive_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode();
  final FocusNode _registerButtonFocusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    _registerButtonFocusNode.dispose();
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

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _announceToTalkBack('Erro: Preencha todos os campos');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: Preencha todos os campos',
            child: const Text('Preencha todos os campos'),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      final user = await _authService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null) {
        throw Exception('Não foi possível entrar com esses dados.');
      }

      await PreferencesService.saveUserName(
        (user as dynamic).email ?? emailController.text.trim(),
      );
      await PreferencesService.saveLogin(true);

      if (!mounted) return;

      _announceToTalkBack('Login realizado com sucesso. Bem-vindo!');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Login realizado com sucesso',
            child: const Text('Bem-vindo!'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } catch (error) {
      if (!mounted) return;
      
      final errorMessage = error.toString();
      _announceToTalkBack('Erro: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: $errorMessage',
            child: Text(errorMessage),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    
    return Semantics(
      container: true,
      label: 'Tela de login',
      child: ResponsiveLayout(
        mobile: _buildMobileLogin(textScale),
        tablet: _buildTabletLogin(textScale),
        desktop: _buildDesktopLogin(textScale),
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================
  Widget _buildMobileLogin(double textScale) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Tela de login',
          child: const Text('Login'),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildForm(textScale),
                const SizedBox(height: 24),
                _buildLoginButton(textScale),
                const SizedBox(height: 12),
                _buildRegisterButton(textScale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLET
  // ============================================================
  Widget _buildTabletLogin(double textScale) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    label: 'SplitMarket - título do aplicativo',
                    child: Text(
                      'SplitMarket',
                      style: TextStyle(
                        fontSize: 32 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildForm(textScale),
                  const SizedBox(height: 24),
                  _buildLoginButton(textScale),
                  const SizedBox(height: 12),
                  _buildRegisterButton(textScale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================
  Widget _buildDesktopLogin(double textScale) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // LADO ESQUERDO - Branding
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ CORRIGIDO: Ícone com semântica adequada
                        Semantics(
                          label: 'Ícone do SplitMarket',
                          // ✅ Remove ícone da árvore de acessibilidade
                          // pois é apenas decorativo
                          child: Icon(
                            Icons.shopping_cart,
                            size: 100 * textScale,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          label: 'SplitMarket - título do aplicativo',
                          child: Text(
                            'SplitMarket',
                            style: TextStyle(
                              fontSize: 42 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Gerencie despesas em grupo com facilidade',
                          child: Text(
                            'Gerencie despesas em grupo com facilidade.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18 * textScale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // LADO DIREITO - Formulário
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          label: 'Entrar - formulário de login',
                          child: Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 32 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildForm(textScale),
                        const SizedBox(height: 24),
                        _buildLoginButton(textScale),
                        const SizedBox(height: 12),
                        _buildRegisterButton(textScale),
                      ],
                    ),
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
  // COMPONENTES ACESSÍVEIS
  // ============================================================
  
  Widget _buildForm(double textScale) {
    return MergeSemantics(
      child: Column(
        children: [
          // 📧 Campo Email
          Semantics(
            textField: true,
            label: 'Email',
            hint: 'Digite seu endereço de email',
            enabled: true,
            child: TextField(
              controller: emailController,
              focusNode: _emailFocusNode,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  fontSize: 16 * textScale,
                ),
                hintText: 'exemplo@email.com',
                hintStyle: TextStyle(
                  fontSize: 14 * textScale,
                  color: Colors.grey[600],
                ),
                errorStyle: TextStyle(
                  fontSize: 14 * textScale,
                ),
              ),
              onEditingComplete: () {
                _emailFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 🔒 Campo Senha
          Semantics(
            textField: true,
            label: 'Senha',
            hint: 'Digite sua senha',
            enabled: true,
            child: TextField(
              controller: passwordController,
              focusNode: _passwordFocusNode,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  fontSize: 16 * textScale,
                ),
                hintText: 'Digite sua senha',
                hintStyle: TextStyle(
                  fontSize: 14 * textScale,
                  color: Colors.grey[600],
                ),
                errorStyle: TextStyle(
                  fontSize: 14 * textScale,
                ),
              ),
              onEditingComplete: () {
                _passwordFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_loginButtonFocusNode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(double textScale) {
    return Semantics(
      button: true,
      label: 'Entrar',
      hint: 'Toque para fazer login',
      enabled: true,
      child: SizedBox(
        width: double.infinity,
        height: 50 * textScale.clamp(0.8, 1.5),
        child: ElevatedButton(
          focusNode: _loginButtonFocusNode,
          onPressed: login,
          child: Text(
            'Entrar',
            style: TextStyle(
              fontSize: 18 * textScale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(double textScale) {
    return Semantics(
      button: true,
      label: 'Criar conta',
      hint: 'Toque para criar uma nova conta',
      enabled: true,
      child: TextButton(
        focusNode: _registerButtonFocusNode,
        onPressed: () {
          _announceToTalkBack('Navegando para tela de cadastro');
          
          Navigator.pushNamed(
            context,
            '/register',
          );
        },
        child: Text(
          'Criar conta',
          style: TextStyle(
            fontSize: 16 * textScale,
          ),
        ),
      ),
    );
  }
}