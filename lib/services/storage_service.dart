import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Persists auth token and user data locally.
class StorageService {
  static const String _kToken = 'auth_token';
  static const String _kUser = 'auth_user';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveToken(String token) async {
    final p = await _getPrefs();
    await p.setString(_kToken, token);
  }

  static Future<String?> getToken() async {
    final p = await _getPrefs();
    return p.getString(_kToken);
  }

  static Future<void> clearToken() async {
    final p = await _getPrefs();
    await p.remove(_kToken);
  }

  static Future<void> saveUser(User user) async {
    final p = await _getPrefs();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final p = await _getPrefs();
    final raw = p.getString(_kUser);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    final p = await _getPrefs();
    await p.remove(_kToken);
    await p.remove(_kUser);
  }
}
