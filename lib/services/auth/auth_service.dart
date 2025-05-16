import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:logger/logger.dart';
import '../pocketbase_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  final SharedPreferences _prefs;
  final _logger = Logger();
  late final Future<PocketBase> _client;

  AuthService(this._prefs) {
    _client = PocketBaseService.instance;
  }

  bool get isAuthenticated => PocketBaseService.isAuthenticated;

  Future<PocketBase> getClient() => _client;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;
    return json.decode(userJson) as Map<String, dynamic>;
  }

  Future<bool> login(String email, String password) async {
    try {
      final pb = await _client;
      final authData = await pb.collection('users').authWithPassword(
        email,
        password,
      );

      await _prefs.setString(_userKey, json.encode(authData.record?.data));
      return true;
    } catch (e) {
      _logger.e('Login failed: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    try {
      final pb = await _client;
      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'username': username,
      };

      final record = await pb.collection('users').create(body: userData);
      _logger.i('User registered successfully: ${record.id}');
      
      return await login(email, password);
    } catch (e) {
      _logger.e('Registration failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_userKey);
    await PocketBaseService.clearAuthStore();
  }

  Future<bool> resetPassword(String email) async {
    try {
      final pb = await _client;
      await pb.collection('users').requestPasswordReset(email);
      return true;
    } catch (e) {
      _logger.e('Password reset request failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    final pb = await _client;
    return pb.authStore.token;
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    try {
      final pb = await _client;
      final updatedUser = await pb.collection('users').update(
        currentUser['id'],
        body: userData,
      );

      await _prefs.setString(_userKey, json.encode(updatedUser.data));
    } catch (e) {
      _logger.e('Profile update failed: $e');
      rethrow;
    }
  }
} 