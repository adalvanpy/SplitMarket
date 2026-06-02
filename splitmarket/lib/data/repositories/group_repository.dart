import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../../core/services/api_service.dart';

class GroupProvider extends ChangeNotifier {
  final ApiService _service = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GroupModel> grupos = [];
  bool carregando = false;

  Future<void> carregarGrupos() async {
    carregando = true;
    notifyListeners();

    try {
      grupos = await _service.listarGrupos();
    } catch (e) {
      print('Erro ao carregar grupos: $e');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // 👈 IMPLEMENTAÇÃO DO CRIAR GRUPO
  Future<void> criarGrupo(String nome) async {
    carregando = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não está logado');
      }

      // Criar novo grupo
      final novoGrupo = GroupModel(
        id: '', // Será gerado pelo Firestore
        nome: nome,
        membros: [userId], // Adiciona o criador como primeiro membro
        criadorId: userId,
        createdAt: DateTime.now(),
      );

      // Salvar no Firestore
      final docRef = await _firestore.collection('groups').add({
        'nome': novoGrupo.nome,
        'membros': novoGrupo.membros,
        'criadorId': novoGrupo.criadorId,
        'createdAt': novoGrupo.createdAt.toIso8601String(),
      });

      // Atualizar o ID do grupo
      final grupoSalvo = GroupModel(
        id: docRef.id,
        nome: novoGrupo.nome,
        membros: novoGrupo.membros,
        criadorId: novoGrupo.criadorId,
        createdAt: novoGrupo.createdAt,
      );

      // Adicionar à lista local
      grupos.add(grupoSalvo);
      
      // Também salvar via ApiService se necessário
      await _service.criarGrupo(grupoSalvo);
      
      print('✅ Grupo criado: ${grupoSalvo.nome} (ID: ${grupoSalvo.id})');
      
    } catch (e) {
      print('❌ Erro ao criar grupo: $e');
      rethrow;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // 👈 MÉTODO PARA ADICIONAR MEMBRO AO GRUPO
  Future<void> adicionarMembro(String groupId, String userEmail) async {
    carregando = true;
    notifyListeners();

    try {
      // Buscar usuário pelo email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Usuário com email $userEmail não encontrado');
      }

      final userId = userQuery.docs.first.id;
      final grupo = grupos.firstWhere((g) => g.id == groupId);

      // Adicionar membro
      final novosMembros = [...grupo.membros, userId];
      
      await _firestore.collection('groups').doc(groupId).update({
        'membros': novosMembros,
      });

      // Atualizar lista local
      final index = grupos.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        grupos[index] = grupos[index].copyWith(membros: novosMembros);
      }

      print('✅ Membro adicionado ao grupo');
      
    } catch (e) {
      print('❌ Erro ao adicionar membro: $e');
      rethrow;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Alias para adicionarMembro
  Future<void> adicionarParticipante(String groupId, String userEmail) async {
    return adicionarMembro(groupId, userEmail);
  }

  // 👈 MÉTODO PARA REMOVER GRUPO
  Future<void> removerGrupo(String groupId) async {
    carregando = true;
    notifyListeners();

    try {
      await _firestore.collection('groups').doc(groupId).delete();
      
      grupos.removeWhere((g) => g.id == groupId);
      
      print('✅ Grupo removido');
      
    } catch (e) {
      print('❌ Erro ao remover grupo: $e');
      rethrow;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // 👈 MÉTODO PARA ATUALIZAR NOME DO GRUPO
  Future<void> atualizarNomeGrupo(String groupId, String novoNome) async {
    carregando = true;
    notifyListeners();

    try {
      await _firestore.collection('groups').doc(groupId).update({
        'nome': novoNome,
      });

      final index = grupos.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        grupos[index] = grupos[index].copyWith(nome: novoNome);
      }

      print('✅ Nome do grupo atualizado');
      
    } catch (e) {
      print('❌ Erro ao atualizar nome do grupo: $e');
      rethrow;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void limparGrupos() {
    grupos = [];
    notifyListeners();
  }
}