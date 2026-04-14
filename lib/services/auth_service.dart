import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final String? token;
  final User? user;
  final String message;

  AuthResult({required this.success, this.token, this.user, required this.message});
}

class AuthService {
  static Future<AuthResult> login(String email, String password) async {
    final res = await ApiService.post(
      ApiConfig.login,
      auth: false,
      body: {'email': email, 'password': password},
    );

    if (res.success && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'];
      User? user;
      if (userData is Map<String, dynamic>) {
        user = User.fromJson(userData);
      }
      if (token != null) {
        await StorageService.saveToken(token);
        if (user != null) await StorageService.saveUser(user);
      }
      return AuthResult(success: true, token: token, user: user, message: res.message);
    }

    return AuthResult(success: false, message: res.message.isNotEmpty ? res.message : 'Login failed');
  }

  static Future<AuthResult> signup(Map<String, String> fields) async {
    final res = await ApiService.post(ApiConfig.signup, auth: false, body: fields);
    if (res.success && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'];
      User? user;
      if (userData is Map<String, dynamic>) {
        user = User.fromJson(userData);
      }
      if (token != null) {
        await StorageService.saveToken(token);
        if (user != null) await StorageService.saveUser(user);
      }
      return AuthResult(success: true, token: token, user: user, message: res.message);
    }
    return AuthResult(success: false, message: res.message.isNotEmpty ? res.message : 'Signup failed');
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout);
    } catch (_) {/* ignore */}
    await StorageService.clearAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
