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

      print('Convite enviado com Sucesso');
      
    } catch (e) {
      print('❌ Erro ao adicionar membro: $e');
      rethrow;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Alias para adicionarMembro
  Future<void> adicionarParticipante(
  String groupId,
  String userEmail,
) async {
  final grupo = grupos.firstWhere(
    (g) => g.id == groupId,
  );

  await enviarConvite(
    groupId,
    grupo.nome,
    userEmail,
  );
}
 Future<void> enviarConvite(
  String groupId,
  String groupName,
  String userEmail,
) async {
  await _firestore
      .collection('group_invites')
      .add({
    'groupId': groupId,
    'groupName': groupName,
    'userEmail': userEmail,
    'status': 'pending',
    'createdAt':
        DateTime.now().toIso8601String(),
  });
}

Future<void> aceitarConvite(
  String inviteId,
  String groupId,
) async {
  final userId =
      FirebaseAuth.instance.currentUser!.uid;

  final groupDoc = await _firestore
      .collection('groups')
      .doc(groupId)
      .get();

  final membros =
      List<String>.from(groupDoc['membros']);

  if (!membros.contains(userId)) {
    membros.add(userId);

    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({
      'membros': membros,
    });
  }

  await _firestore
      .collection('group_invites')
      .doc(inviteId)
      .update({
    'status': 'accepted',
  });
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
Future<void> sairDoGrupo(
  String groupId,
  String userId,
) async {
  try {
    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .get();

    final membros =
        List<String>.from(doc['membros']);

    membros.remove(userId);

    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({
      'membros': membros,
    });

    final index =
        grupos.indexWhere((g) => g.id == groupId);

    if (index != -1) {
      grupos[index] =
          grupos[index].copyWith(
        membros: membros,
      );
    }

    notifyListeners();
  } catch (e) {
    print('Erro ao sair do grupo: $e');
    rethrow;
  }
}
Future<bool> possuiDividasPendentes(
  String groupId,
  String userId,
) async {
  try {
    final snapshot = await _firestore
        .collection('debts')
        .where('groupId', isEqualTo: groupId)
        .where('participant', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.isNotEmpty;
  } catch (e) {
    print('Erro ao verificar dívidas: $e');
    return false;
  }
}
  void limparGrupos() {
    grupos = [];
    notifyListeners();
  }
}