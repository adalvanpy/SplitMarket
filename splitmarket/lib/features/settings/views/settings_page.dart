import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/expense_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/themes/theme_notifier.dart';
import '../../../data/repositories/group_repository.dart';
import '../../notifications/viewmodels/notification_provider.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔤 Fonte dinâmica
    final textScale = MediaQuery.of(context).textScaleFactor;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Semantics(
      container: true,
      label: 'Tela de configurações',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // ============================================
            // Cabeçalho
            // ============================================
            Semantics(
              label: 'Cabeçalho - Configurações',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 50, 24, 40),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Voltar',
                          hint: 'Toque para voltar à tela anterior',
                          child: IconButton(
                            onPressed: () {
                              SemanticsService.announce(
                                'Voltando para tela anterior',
                                Directionality.of(context),
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          header: true,
                          label: 'Configurações - título da página',
                          child: Text(
                            'Configurações',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // ============================================
            // Conteúdo
            // ============================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 🌙 Modo Escuro
                  _buildSettingsCard(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Modo Escuro',
                    subtitle: 'Ativar tema escuro',
                    trailing: Semantics(
                      label: themeNotifier.isDarkMode 
                          ? 'Modo escuro ativado' 
                          : 'Modo escuro desativado',
                      hint: 'Toque para alternar o tema',
                      child: Switch(
                        activeColor: const Color(0xFF8E76F7),
                        value: themeNotifier.isDarkMode,
                        onChanged: (_) {
                          themeNotifier.toggleTheme();
                          SemanticsService.announce(
                            themeNotifier.isDarkMode 
                                ? 'Modo escuro desativado' 
                                : 'Modo escuro ativado',
                            Directionality.of(context),
                          );
                        },
                      ),
                    ),
                    textScale: textScale,
                  ),
                  const SizedBox(height: 16),
                  
                  // 👤 Conta
                  _buildSettingsCard(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Conta',
                    subtitle: 'Editar informações da conta',
                    onTap: () {
                      SemanticsService.announce(
                        'Abrindo perfil do usuário',
                        Directionality.of(context),
                      );
                      Navigator.pushNamed(context, '/profile');
                    },
                    textScale: textScale,
                  ),
                  const SizedBox(height: 16),
                  
                  // 🔔 Notificações
                  FutureBuilder<String>(
                    future: PreferencesService.getUserName(),
                    builder: (context, snapshot) {
                      final currentUser = snapshot.data ?? 'Usuário';
                      return Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, child) {
                          final pendingCount = notificationProvider.pendingCountFor(currentUser);
                          return _buildSettingsCard(
                            context: context,
                            icon: Icons.notifications_outlined,
                            title: 'Notificações',
                            subtitle: 'Pendências de confirmação',
                            onTap: () {
                              SemanticsService.announce(
                                'Abrindo notificações',
                                Directionality.of(context),
                              );
                              Navigator.pushNamed(context, '/notifications');
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pendingCount > 0)
                                  Semantics(
                                    label: '$pendingCount notificações pendentes',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$pendingCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12 * textScale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                ExcludeSemantics(
                                  excluding: true,
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14 * textScale,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textScale: textScale,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // ℹ️ Sobre
                  _buildSettingsCard(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    subtitle: 'Versão do aplicativo',
                    textScale: textScale,
                  ),
                  const SizedBox(height: 32),
                  
                  // 🚪 Botão Sair
                  _buildLogoutButton(context, textScale),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 3),
      ),
    );
  }

  // ============================================================
  // CARD DE CONFIGURAÇÃO ACESSÍVEL
  // ============================================================
  Widget _buildSettingsCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required double textScale,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: '$title: $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone
              ExcludeSemantics(
                excluding: true,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF8E76F7),
                    size: 24 * textScale,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontSize: 13 * textScale,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Trailing
              trailing ??
                  (onTap != null
                      ? ExcludeSemantics(
                          excluding: true,
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14 * textScale,
                            color: Colors.grey,
                          ),
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO SAIR ACESSÍVEL
  // ============================================================
  Widget _buildLogoutButton(BuildContext context, double textScale) {
    return Semantics(
      button: true,
      label: 'Sair da Conta',
      hint: 'Toque para sair da sua conta',
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E76F7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
          onPressed: () async {
            try {
              SemanticsService.announce(
                'Saindo da conta',
                Directionality.of(context),
              );
              
              await AuthService().signOut();
              await PreferencesService.clearUserData();
              context.read<GroupProvider>().limparGrupos();
              
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                final errorMessage = 'Erro ao sair: $e';
                SemanticsService.announce(
                  errorMessage,
                  Directionality.of(context),
                );
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
          },
          icon: ExcludeSemantics(
            excluding: true,
            child: const Icon(Icons.logout, color: Colors.white),
          ),
          label: Text(
            'Sair da Conta',
            style: TextStyle(
              fontSize: 16 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}