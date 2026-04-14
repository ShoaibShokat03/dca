import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> loadFromStorage() async {
    _user = await StorageService.getUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.login(email, password);
      if (result.success) {
        _user = result.user;
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = result.message;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(Map<String, String> fields) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.signup(fields);
      if (result.success) {
        _user = result.user;
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = result.message;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    StorageService.saveUser(user);
    notifyListeners();
  }
}
