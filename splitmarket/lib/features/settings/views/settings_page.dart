import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/theme_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      body: Column(

        children: [

          // Cabeçalho
          Container(

            width: double.infinity,

            padding: const EdgeInsets.fromLTRB(
              16,
              50,
              24,
              40,
            ),

            decoration: const BoxDecoration(

              gradient: LinearGradient(

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

                colors: [
                  Color(0xFF8E76F7),
                  Color(0xFFB993F9),
                ],
              ),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    IconButton(

                      onPressed: () =>
                          Navigator.pop(context),

                      icon: const Icon(

                        Icons.arrow_back_ios_new,

                        color: Colors.white,

                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Text(

                      'Configurações',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 26,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo
          Expanded(

            child: ListView(

              padding: const EdgeInsets.all(24),

              children: [

                _buildSettingsCard(

                  context,

                  icon:
                      Icons.dark_mode_outlined,

                  title: 'Modo Escuro',

                  subtitle:
                      'Ativar tema escuro',

                  trailing:
                      Consumer<ThemeNotifier>(

                    builder: (

                      context,

                      themeNotifier,

                      child,
                    ) {

                      return Switch(

                        activeColor:
                            const Color(
                          0xFF8E76F7,
                        ),

                        value:
                            themeNotifier
                                .isDarkMode,

                        onChanged: (value) {

                          themeNotifier
                              .toggleTheme();
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _buildSettingsCard(

                  context,

                  icon: Icons.person_outline,

                  title: 'Conta',

                  subtitle:
                      'Editar informações da conta',
                ),

                const SizedBox(height: 16),

                _buildSettingsCard(

                  context,

                  icon:
                      Icons.notifications_outlined,

                  title: 'Notificações',

                  subtitle:
                      'Gerenciar alertas do app',
                ),

                const SizedBox(height: 16),

                _buildSettingsCard(

                  context,

                  icon: Icons.info_outline,

                  title: 'Sobre',

                  subtitle:
                      'Versão do aplicativo',
                ),

                const SizedBox(height: 32),

                // Botão sair
                SizedBox(

                  width: double.infinity,

                  height: 55,

                  child: ElevatedButton.icon(

                    style:
                        ElevatedButton.styleFrom(

                      backgroundColor:
                          const Color(
                        0xFF8E76F7,
                      ),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),

                      elevation: 2,
                    ),

                    onPressed: () {},

                    icon: const Icon(
                      Icons.logout,
                    ),

                    label: const Text(

                      'Sair da Conta',

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(

        decoration: BoxDecoration(

          color:
              Theme.of(context).cardColor,

          boxShadow: [

            BoxShadow(

              color:
                  Colors.black.withOpacity(
                0.05,
              ),

              blurRadius: 10,

              offset: const Offset(0, -5),
            ),
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: 3,

          type:
              BottomNavigationBarType.fixed,

          backgroundColor:
              Theme.of(context).cardColor,

          selectedItemColor:
              const Color(0xFF8E76F7),

          unselectedItemColor:
              Colors.grey,

          showUnselectedLabels: true,

          onTap: (index) {

            final routes = [

              '/add-expense',
              '/expenses',
              '/summary',
              '/settings',
            ];

            if (index == 3) return;

            Navigator.pushNamed(
              context,
              routes[index],
            );
          },

          items: const [

            BottomNavigationBarItem(

              icon: Icon(
                Icons.add_circle_outline,
              ),

              label: 'Adicionar',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.receipt_long_outlined,
              ),

              label: 'Despesas',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.analytics_outlined,
              ),

              label: 'Resumo',
            ),

            BottomNavigationBarItem(

              icon: Icon(
                Icons.settings_outlined,
              ),

              label: 'Configurações',
            ),
          ],
        ),
      ),
    );
  }

  // Card padronizado
  Widget _buildSettingsCard(

    BuildContext context, {

    required IconData icon,

    required String title,

    required String subtitle,

    Widget? trailing,
  }) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color:
            Theme.of(context).cardColor,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withOpacity(
              0.03,
            ),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(

        children: [

          Container(

            padding:
                const EdgeInsets.all(10),

            decoration: BoxDecoration(

              color: const Color(
                0xFFF0EDFF,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(

              icon,

              color: const Color(
                0xFF8E76F7,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: TextStyle(

                    fontSize: 16,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color,
                  ),
                ),

                const SizedBox(height: 4),

                Text(

                  subtitle,

                  style: TextStyle(

                    color: Colors.grey[600],

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          trailing ??

              const Icon(

                Icons.arrow_forward_ios,

                size: 14,

                color: Colors.grey,
              ),
        ],
      ),
    );
  }
}