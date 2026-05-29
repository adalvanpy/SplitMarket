// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class LocalUser {
  final String? email;
  LocalUser(this.email);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<LocalUser?> register(String email, String password) async {
    try {
      print('🟡 [AuthService] Iniciando cadastro para: $email');
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ [AuthService] Cadastro bem sucedido!');
      print('✅ [AuthService] Email: ${userCredential.user?.email}');
      print('✅ [AuthService] UID: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        return LocalUser(userCredential.user!.email);
      }
      return null;
      
    } on FirebaseAuthException catch (e) {
      print('❌ [AuthService] FirebaseAuthException:');
      print('   Código: ${e.code}');
      print('   Mensagem: ${e.message}');
      
      if (e.code == 'weak-password') {
        throw Exception('A senha é muito fraca. Use pelo menos 6 caracteres.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Este email já está cadastrado.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Cadastro desabilitado no Firebase. Ative o provedor de email/senha.');
      } else {
        throw Exception('Erro no cadastro: ${e.message}');
      }
    } catch (e) {
      print('❌ [AuthService] Erro inesperado: $e');
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<LocalUser?> signIn(String email, String password) async {
    try {
      print('🟡 [AuthService] Iniciando login para: $email');
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ [AuthService] Login bem sucedido!');
      
      if (userCredential.user != null) {
        return LocalUser(userCredential.user!.email);
      }
      return null;
      
    } on FirebaseAuthException catch (e) {
      print('❌ [AuthService] Erro no login: ${e.code}');
      
      if (e.code == 'user-not-found') {
        throw Exception('Usuário não encontrado.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Senha incorreta.');
      } else {
        throw Exception('Erro no login: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    print('✅ [AuthService] Logout realizado');
  }

  LocalUser? get currentUser {
    final user = _auth.currentUser;
    return user != null ? LocalUser(user.email) : null;
  }
}
