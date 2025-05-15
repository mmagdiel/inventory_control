import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  final SharedPreferences _prefs;
  final _client = PocketBase('http://127.0.0.1:8090/api/');

  AuthService(this._prefs);

  bool get isAuthenticated => _prefs.getString(_tokenKey) != null;

  PocketBase getClient() => _client;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;
    return json.decode(userJson) as Map<String, dynamic>;
  }

  Future<bool> login(String email, String password) async {
    try {
      final authData = await _client.collection('users').authWithPassword(
        email,
        password,
      );

      await _prefs.setString(_tokenKey, authData.token);
      await _prefs.setString(_userKey, json.encode(authData.record?.data));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    try {
      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'username': username,
      };

      await _client.collection('users').create(body: userData);
      return await login(email, password);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    _client.authStore.clear();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _client.collection('users').requestPasswordReset(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    try {
      final updatedUser = await _client.collection('users').update(
        currentUser['id'],
        body: userData,
      );

      await _prefs.setString(_userKey, json.encode(updatedUser.data));
    } catch (e) {
      rethrow;
    }
  }
} 