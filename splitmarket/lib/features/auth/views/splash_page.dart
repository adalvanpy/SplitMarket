import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔤 Fonte dinâmica - respeita configurações do sistema
    final textScale = MediaQuery.of(context).textScaleFactor;
    
    return Semantics(
      container: true,
      label: 'Tela de abertura do SplitMarket',
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 Ícone decorativo (opcional - adicionei para melhor experiência)
              Semantics(
                label: 'Logo do SplitMarket',
                child: Icon(
                  Icons.shopping_cart,
                  size: 80 * textScale,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // 📝 Título principal
              Semantics(
                header: true,
                label: 'SplitMarket - aplicativo de gerenciamento de despesas em grupo',
                child: Text(
                  'SplitMarket',
                  style: TextStyle(
                    fontSize: 32 * textScale,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // 📝 Subtítulo
              Semantics(
                label: 'Gerencie despesas em grupo com facilidade',
                child: Text(
                  'Gerencie despesas em grupo com facilidade',
                  style: TextStyle(
                    fontSize: 16 * textScale,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // ⏳ Indicador de carregamento
              Semantics(
                label: 'Carregando aplicativo, aguarde',
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 📌 Texto de carregamento
              Semantics(
                label: 'Aguarde enquanto o aplicativo é carregado',
                child: Text(
                  'Carregando...',
                  style: TextStyle(
                    fontSize: 14 * textScale,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}