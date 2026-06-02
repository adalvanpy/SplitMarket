import '../../../core/services/auth_service.dart';

class LoginController {
  final AuthService authService;

  LoginController(this.authService);

  Future<bool> fazerLogin(
    String user,
    String pass,
  ) async {
    try {
      final userCredential = await authService.signIn(user, pass);
      return userCredential != null;
    } catch (_) {
      return false;
    }
  }
}
