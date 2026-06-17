import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';
import '../../../core/services/location_service.dart';

class AddExpensePage extends StatefulWidget {
  final String? grupoId;

  const AddExpensePage({super.key, this.grupoId});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController payerController = TextEditingController();
  
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  String _address = 'Buscando localização...';
  String _userName = '';
  bool _isLoading = true;

  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _valueFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadLocation();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    payerController.dispose();
    _descriptionFocusNode.dispose();
    _valueFocusNode.dispose();
    _saveButtonFocusNode.dispose();
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

  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        final endereco = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentPosition = LatLng(
            position.latitude,
            position.longitude,
          );
          _address = endereco;
        });
        
        _announceToTalkBack('Localização carregada: $endereco');
      }
    } catch (e) {
      setState(() {
        _address = 'Erro ao obter localização';
      });
      _announceToTalkBack('Erro ao obter localização');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (doc.exists) {
          final nome = doc.data()?['name'] ?? '';
          setState(() {
            _userName = nome;
            payerController.text = nome;
            _isLoading = false;
          });
        } else {
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          setState(() {
            _userName = email.split('@')[0];
            payerController.text = _userName;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar nome: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Tela de adicionar nova despesa',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _isLoading
            ? Center(
                child: Semantics(
                  label: 'Carregando dados do usuário',
                  child: const CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ============================================
                    // Cabeçalho
                    // ============================================
                    Semantics(
                      label: 'Cabeçalho - Nova Despesa',
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
                                      _announceToTalkBack('Voltando para tela anterior');
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
                                  label: 'Nova Despesa - título da página',
                                  child: Text(
                                    'Nova Despesa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26 * textScale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              label: 'Preencha os detalhes abaixo para registrar um novo gasto.',
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Preencha os detalhes abaixo para registrar um novo gasto.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16 * textScale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ============================================
                    // Formulário
                    // ============================================
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildStyledTextField(
                            context,
                            controller: descriptionController,
                            focusNode: _descriptionFocusNode,
                            label: 'Descrição',
                            hint: 'Ex: Pizza, Cinema, Mercado...',
                            icon: Icons.description_outlined,
                            textScale: textScale,
                            onEditingComplete: () {
                              _descriptionFocusNode.unfocus();
                              FocusScope.of(context).requestFocus(_valueFocusNode);
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          _buildStyledTextField(
                            context,
                            controller: valueController,
                            focusNode: _valueFocusNode,
                            label: 'Valor (R\$)',
                            hint: '0,00',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            textScale: textScale,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]'),
                              ),
                            ],
                            onEditingComplete: () {
                              _valueFocusNode.unfocus();
                              FocusScope.of(context).requestFocus(_saveButtonFocusNode);
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          _buildStyledTextField(
                            context,
                            controller: payerController,
                            focusNode: null,
                            label: 'Quem pagou?',
                            hint: 'Nome de quem pagou',
                            icon: Icons.person_outline,
                            textScale: textScale,
                            enabled: false,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Semantics(
                            label: 'O pagador é definido automaticamente como você.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.blue : Colors.blue.shade50).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isDark ? Colors.blue.shade800 : Colors.blue.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18 * textScale,
                                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'O pagador é definido automaticamente como você.',
                                      style: TextStyle(
                                        fontSize: 13 * textScale,
                                        color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // ============================================
                          // Localização - CORRIGIDO
                          // ============================================
                          Semantics(
                            header: true,
                            label: 'Localização da despesa',
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Localização da despesa',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 🗺️ Mapa - CORRIGIDO com ExcludeSemantics
                          Semantics(
                            label: 'Mapa mostrando a localização da despesa',
                            child: ExcludeSemantics(
                              excluding: true,  // ✅ CORRETO!
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _currentPosition == null
                                  ? Center(
                                      child: Semantics(
                                        label: 'Carregando localização...',
                                        child: const CircularProgressIndicator(),
                                      ),
                                    )
                                  : FlutterMap(
                                      options: MapOptions(
                                        initialCenter: _currentPosition!,
                                        initialZoom: 15,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.example.splitmarket',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _currentPosition!,
                                              width: 40,
                                              height: 40,
                                              child: Semantics(
                                                label: 'Marcador de localização',
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 📍 Endereço
                          Semantics(
                            label: 'Endereço: $_address',
                            child: Text(
                              _address,
                              style: TextStyle(
                                fontSize: 13 * textScale,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ============================================
                          // Botão Salvar
                          // ============================================
                          Semantics(
                            button: true,
                            label: 'Salvar Despesa',
                            hint: 'Toque para salvar a despesa',
                            enabled: true,
                            child: SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                focusNode: _saveButtonFocusNode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8E76F7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _saveExpense,
                                child: Text(
                                  'Salvar Despesa',
                                  style: TextStyle(
                                    fontSize: 18 * textScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: const CustomBottomNavbar(currentIndex: 0),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (descriptionController.text.isEmpty || valueController.text.isEmpty) {
      _announceToTalkBack('Erro: Preencha todos os campos');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Erro: Preencha todos os campos',
            child: const Text('Preencha todos os campos'),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      String valorStr = valueController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      double valor = double.parse(valorStr);

      final expense = ExpenseModel(
        description: descriptionController.text,
        value: valor,
        payer: payerController.text,
        grupoId: widget.grupoId,
        createdAt: DateTime.now(),
        location: _address,
      );

      await context.read<ExpenseProvider>().adicionarDespesa(expense);

      if (!mounted) return;

      _announceToTalkBack('Despesa salva com sucesso!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Despesa salva com sucesso!',
            child: const Text('Despesa salva com sucesso!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = 'Erro ao salvar: $e';
      _announceToTalkBack(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: errorMessage,
            child: Text(errorMessage),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildStyledTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    required double textScale,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onEditingComplete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      enabled: enabled,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          enabled: enabled,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 16 * textScale,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(
              fontSize: 16 * textScale,
              color: enabled ? Colors.grey : (isDark ? Colors.white60 : Colors.grey),
            ),
            hintStyle: TextStyle(
              fontSize: 14 * textScale,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF8E76F7),
              size: 24 * textScale,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * textScale,
              vertical: 16 * textScale,
            ),
          ),
          onEditingComplete: onEditingComplete,
        ),
      ),
    );
  }
}