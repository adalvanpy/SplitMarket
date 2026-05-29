// lib/core/services/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Chaves para armazenamento
  static const String _keyUserLogged = 'user_logged';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id';
  static const String _keyTheme = 'theme_mode';

  // ==================== LOGIN STATUS ====================
  
  static Future<bool> isLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUserLogged) ?? false;
  }

  static Future<bool> getLogin() async {
    return await isLogged();
  }

  static Future<void> saveLogin(bool isLogged) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUserLogged, isLogged);
  }

  // ==================== LOGOUT ====================
  
  /// Faz logout do usuário (limpa todos os dados de autenticação)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserLogged);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserId);
    // Não remove o tema para manter a preferência do usuário
  }

  // ==================== USER NAME ====================
  
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Usuário';
  }

  // ==================== USER EMAIL ====================
  
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail) ?? '';
  }

  // ==================== USER ID ====================
  
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? '';
  }

  // ==================== THEME ====================
  
  static Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isDarkMode);
  }

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? false;
  }

  // ==================== UTILS ====================
  
  /// Alias para logout - mantido para compatibilidade
  static Future<void> clearUserData() async {
    await logout();
  }

  static Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserEmail);
  }

  static Future<void> saveUserData({
    required String email,
    required String userId,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserId, userId);
    if (name != null) {
      await prefs.setString(_keyUserName, name);
    }
    await prefs.setBool(_keyUserLogged, true);
  }

  // ==================== MÉTODOS DELEGADOS (Compatibilidade) ====================
  
  static Future<void> saveLoginStatus(bool isLogged) async {
    await saveLogin(isLogged);
  }

  static Future<bool> getLoginStatus() async {
    return await isLogged();
  }

  static Future<void> saveUserInfo(String email, String name) async {
    await saveUserEmail(email);
    await saveUserName(name);
  }
}