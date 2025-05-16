import 'package:inventory_control/services/database/database_service.dart';
import 'package:inventory_control/services/auth/auth_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:logger/logger.dart';
import 'package:inventory_control/config/app_config.dart';

class SyncService {
  final DatabaseService _db;
  final AuthService _auth;
  late final PocketBase _client;
  final _logger = Logger();

  SyncService(this._db, this._auth) {
    _client = PocketBase(AppConfig.apiUrl);
  }

  Future<void> syncData() async {
    final token = await _auth.getToken();
    if (token == null) return;

    _client.authStore.save(token, null); // Set the auth token

    // Sync products
    await _syncProducts();
    
    // Sync inventory movements
    await _syncInventoryMovements();
  }

  Future<void> _syncProducts() async {
    try {
      // Upload local changes
      final unsyncedProducts = await _db.getUnsyncedProducts();
      for (final product in unsyncedProducts) {
        final id = product['id'] as String;
        try {
          await _client.collection('products').update(id, body: product);
          await _db.markAsSynced('products', id);
        } catch (e) {
          // Handle conflict or error
          _logger.e('Error syncing product $id: $e');
        }
      }

      // Download server changes
      final serverProducts = await _client.collection('products').getFullList();
      for (final product in serverProducts) {
        final localProduct = await _db.getProduct(product.id);
        if (localProduct == null || 
            (localProduct['updated_at'] as int) < (product.data['updated_at'] as int)) {
          await _db.insertProduct(product.data);
          await _db.markAsSynced('products', product.id);
        }
      }
    } catch (e) {
      _logger.e('Error during product sync: $e');
      rethrow;
    }
  }

  Future<void> _syncInventoryMovements() async {
    try {
      // Upload local changes
      final unsyncedMovements = await _db.getUnsyncedMovements();
      for (final movement in unsyncedMovements) {
        final id = movement['id'] as String;
        try {
          await _client.collection('inventory_movements').update(id, body: movement);
          await _db.markAsSynced('inventory_movements', id);
        } catch (e) {
          // Handle conflict or error
          _logger.e('Error syncing movement $id: $e');
        }
      }

      // Download server changes
      final serverMovements = await _client.collection('inventory_movements').getFullList();
      for (final movement in serverMovements) {
        final localMovement = await _db.getProduct(movement.id);
        if (localMovement == null || 
            (localMovement['updated_at'] as int) < (movement.data['updated_at'] as int)) {
          await _db.insertInventoryMovement(movement.data);
          await _db.markAsSynced('inventory_movements', movement.id);
        }
      }
    } catch (e) {
      _logger.e('Error during inventory movement sync: $e');
      rethrow;
    }
  }
} 