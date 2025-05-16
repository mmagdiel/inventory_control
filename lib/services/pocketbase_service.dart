import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'auth_store.dart';

class PocketBaseService {
  static PocketBase? _instance;
  static SharedPreferencesAuthStore? _authStore;

  static Future<PocketBase> get instance async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _authStore = SharedPreferencesAuthStore(prefs);
      _instance = PocketBase(
        AppConfig.apiUrl,
        authStore: _authStore,
      );
    }
    return _instance!;
  }

  static Future<void> clearAuthStore() async {
    _authStore?.clear();
  }

  static bool get isAuthenticated => _authStore?.isValid ?? false;
} 