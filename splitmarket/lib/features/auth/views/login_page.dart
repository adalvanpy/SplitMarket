import 'package:flutter/material.dart';

import '../../../core/services/preferences_service.dart';
import '../../../widgets/responsive_layout.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {

  final TextEditingController
      emailController =
          TextEditingController();

  final TextEditingController
      passwordController =
          TextEditingController();

  @override
  void dispose() {

    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  Future<void> login() async {

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Preencha todos os campos',
          ),
        ),
      );

      return;
    }

    await PreferencesService
        .saveLogin(true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/home',
    );
  }

  @override
  Widget build(BuildContext context) {

    return ResponsiveLayout(

      mobile: _buildMobileLogin(),

      tablet: _buildTabletLogin(),

      desktop: _buildDesktopLogin(),
    );
  }

  // MOBILE

  Widget _buildMobileLogin() {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Login'),
      ),

      body: SafeArea(

        child: Center(

          child: SingleChildScrollView(

            padding:
                const EdgeInsets.all(24),

            child: Column(

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                _buildForm(),

                const SizedBox(height: 24),

                _buildLoginButton(),

                const SizedBox(height: 12),

                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TABLET

  Widget _buildTabletLogin() {

    return Scaffold(

      body: SafeArea(

        child: Center(

          child: SizedBox(

            width: 500,

            child: SingleChildScrollView(

              padding:
                  const EdgeInsets.all(32),

              child: Column(

                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  const Text(
                    'SplitMarket',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildForm(),

                  const SizedBox(height: 24),

                  _buildLoginButton(),

                  const SizedBox(height: 12),

                  _buildRegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // DESKTOP

  Widget _buildDesktopLogin() {

    return Scaffold(

      body: SafeArea(

        child: Row(

          children: [

            // LADO ESQUERDO

            Expanded(

              flex: 2,

              child: Container(

                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,

                child: Center(

                  child: Padding(

                    padding:
                        const EdgeInsets.all(48),

                    child: Column(

                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [

                        Icon(
                          Icons.shopping_cart,
                          size: 100,
                          color: Theme.of(
                                  context)
                              .colorScheme
                              .primary,
                        ),

                        const SizedBox(
                            height: 24),

                        const Text(

                          'SplitMarket',

                          style: TextStyle(
                            fontSize: 42,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                            height: 16),

                        const Text(

                          'Gerencie despesas em grupo com facilidade.',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // LADO DIREITO

            Expanded(

              child: Center(

                child: SizedBox(

                  width: 420,

                  child: SingleChildScrollView(

                    padding:
                        const EdgeInsets
                            .all(32),

                    child: Column(

                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        const Text(

                          'Entrar',

                          style: TextStyle(
                            fontSize: 32,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                            height: 32),

                        _buildForm(),

                        const SizedBox(
                            height: 24),

                        _buildLoginButton(),

                        const SizedBox(
                            height: 12),

                        _buildRegisterButton(),
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

  // COMPONENTES

  Widget _buildForm() {

    return Column(

      children: [

        TextField(

          controller: emailController,

          decoration:
              const InputDecoration(

            labelText: 'Email',

            border:
                OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        TextField(

          controller:
              passwordController,

          obscureText: true,

          decoration:
              const InputDecoration(

            labelText: 'Senha',

            border:
                OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {

    return SizedBox(

      width: double.infinity,

      height: 50,

      child: ElevatedButton(

        onPressed: login,

        child: const Text('Entrar'),
      ),
    );
  }

  Widget _buildRegisterButton() {

    return TextButton(

      onPressed: () {

        Navigator.pushNamed(
          context,
          '/register',
        );
      },

      child:
          const Text('Criar conta'),
    );
  }
}