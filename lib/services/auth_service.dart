import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';

class AuthService {
  static Future<RecordModel?> login(String email, String password) async {
    final pb = await PocketBaseService.instance;
    
    try {
      final authData = await pb.collection('users').authWithPassword(
        email,
        password,
      );
      
      return authData.record;
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    await PocketBaseService.clearAuthStore();
  }

  static Future<bool> isAuthenticated() async {
    return PocketBaseService.isAuthenticated;
  }

  static Future<RecordModel?> getCurrentUser() async {
    final pb = await PocketBaseService.instance;
    return pb.authStore.model as RecordModel?;
  }
} 