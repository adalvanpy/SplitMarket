import '../services/auth_service.dart';

class LoginController {
  final AuthService authService;

  LoginController(this.authService);

  bool fazerLogin(String user, String pass) {
    return authService.login(user, pass);
  }
}