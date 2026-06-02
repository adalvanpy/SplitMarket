import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';


import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadLocation();

  }
  Future<void> _loadLocation() async {
  try {
    final position =
        await _locationService.getCurrentLocation();

    if (position != null) {
      final endereco =
          await _locationService.getAddressFromCoordinates(
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
    }
  } catch (e) {
    setState(() {
      _address = 'Erro ao obter localização';
    });
  }
}

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    payerController.dispose();
    super.dispose();
  }

  // Carregar nome do usuário do Firestore
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
      print('Erro ao carregar nome: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Cabeçalho
                  Container(
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
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Nova Despesa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Preencha os detalhes abaixo para registrar um novo gasto.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Formulário
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildStyledTextField(
                          context,
                          controller: descriptionController,
                          label: 'Descrição',
                          hint: 'Ex: Pizza, Cinema, Mercado...',
                          icon: Icons.description_outlined,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildStyledTextField(
                          context,
                          controller: valueController,
                          label: 'Valor (R\$)',
                          hint: '0,00',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildStyledTextField(
                          context,
                          controller: payerController,
                          label: 'Quem pagou?',
                          hint: 'Nome de quem pagou',
                          icon: Icons.person_outline,
                          enabled: false,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Aviso informativo
                        Container(
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
                                size: 18,
                                color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'O pagador é definido automaticamente como você.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Localização da despesa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _currentPosition == null
                          ? const Center(
                              child: CircularProgressIndicator(),
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
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
),

const SizedBox(height: 12),

Text(
  _address,
  style: const TextStyle(
    fontSize: 13,
  ),
),

const SizedBox(height: 40),

                        // Botão salvar
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E76F7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (descriptionController.text.isEmpty ||
                                  valueController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Preencha todos os campos'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                // Converter valor (suporta vírgula)
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
                                );

                                await context.read<ExpenseProvider>().adicionarDespesa(expense);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Despesa salva com sucesso!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao salvar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Salvar Despesa',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
    );
  }

  // Campo estilizado
  Widget _buildStyledTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey : (isDark ? Colors.white60 : Colors.grey),
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF8E76F7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}