import 'package:flutter/material.dart';

import '../../../core/services/preferences_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              TextField(
                controller: emailController,

                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,

                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(

                  onPressed: () async {

                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preencha todos os campos',
                          ),
                        ),
                      );

                      return;
                    }

                    await PreferencesService.saveLogin(true);

                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                    );
                  },

                  child: const Text('Entrar'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(

                onPressed: () {

                  Navigator.pushNamed(
                    context,
                    '/register',
                  );
                },

                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}