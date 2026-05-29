// lib/core/services/api_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/group_model.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Listar grupos do usuário atual
  Future<List<GroupModel>> listarGrupos() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return [];
      }

      // Buscar grupos onde o usuário é membro
      final querySnapshot = await _firestore
          .collection('groups')
          .where('membros', arrayContains: userId)
          .get();

      final grupos = querySnapshot.docs.map((doc) {
        return GroupModel(
          id: doc.id,
          nome: doc.data()['nome'] ?? '',
          membros: List<String>.from(doc.data()['membros'] ?? []),
          criadorId: doc.data()['criadorId'] ?? '',
          createdAt: doc.data()['createdAt'] != null
              ? DateTime.parse(doc.data()['createdAt'])
              : DateTime.now(),
        );
      }).toList();

      return grupos;
      
    } catch (e) {
      print('Erro ao listar grupos: $e');
      return [];
    }
  }

  // Criar novo grupo
  Future<GroupModel> criarGrupo(GroupModel grupo) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não está logado');
      }

      // Garantir que o criador está na lista de membros
      final membros = grupo.membros.contains(userId) 
          ? grupo.membros 
          : [...grupo.membros, userId];

      final docRef = await _firestore.collection('groups').add({
        'nome': grupo.nome,
        'membros': membros,
        'criadorId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return GroupModel(
        id: docRef.id,
        nome: grupo.nome,
        membros: membros,
        criadorId: userId,
        createdAt: DateTime.now(),
      );
      
    } catch (e) {
      print('Erro ao criar grupo: $e');
      rethrow;
    }
  }

  // Buscar grupo por ID
  Future<GroupModel?> buscarGrupoPorId(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      
      if (doc.exists) {
        return GroupModel(
          id: doc.id,
          nome: doc.data()?['nome'] ?? '',
          membros: List<String>.from(doc.data()?['membros'] ?? []),
          criadorId: doc.data()?['criadorId'] ?? '',
          createdAt: doc.data()?['createdAt'] != null
              ? DateTime.parse(doc.data()?['createdAt'])
              : DateTime.now(),
        );
      }
      return null;
      
    } catch (e) {
      print('Erro ao buscar grupo: $e');
      return null;
    }
  }

  // Adicionar membro ao grupo
  Future<void> adicionarMembro(String groupId, String userEmail) async {
    try {
      // Buscar usuário pelo email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Usuário com email $userEmail não encontrado');
      }

      final userId = userQuery.docs.first.id;
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (!groupDoc.exists) {
        throw Exception('Grupo não encontrado');
      }

      final membrosAtuais = List<String>.from(groupDoc.data()?['membros'] ?? []);
      
      if (!membrosAtuais.contains(userId)) {
        await _firestore.collection('groups').doc(groupId).update({
          'membros': FieldValue.arrayUnion([userId]),
        });
      }
      
    } catch (e) {
      print('Erro ao adicionar membro: $e');
      rethrow;
    }
  }

  // Remover membro do grupo
  Future<void> removerMembro(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'membros': FieldValue.arrayRemove([userId]),
      });
      
    } catch (e) {
      print('Erro ao remover membro: $e');
      rethrow;
    }
  }

  // Atualizar nome do grupo
  Future<void> atualizarNomeGrupo(String groupId, String novoNome) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'nome': novoNome,
      });
      
    } catch (e) {
      print('Erro ao atualizar nome do grupo: $e');
      rethrow;
    }
  }

  // Deletar grupo
  Future<void> deletarGrupo(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      
    } catch (e) {
      print('Erro ao deletar grupo: $e');
      rethrow;
    }
  }

  // Buscar membros do grupo
  Future<List<Map<String, dynamic>>> buscarMembrosDoGrupo(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (!groupDoc.exists) {
        return [];
      }

      final membrosIds = List<String>.from(groupDoc.data()?['membros'] ?? []);
      
      if (membrosIds.isEmpty) {
        return [];
      }

      // Buscar dados dos membros
      final membrosSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: membrosIds)
          .get();

      return membrosSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nome': doc.data()['name'] ?? '',
          'email': doc.data()['email'] ?? '',
        };
      }).toList();
      
    } catch (e) {
      print('Erro ao buscar membros: $e');
      return [];
    }
  }
}