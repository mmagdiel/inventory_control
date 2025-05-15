import 'package:sqflite/sqflite.dart';

class DatabaseService {
  final Database _db;

  DatabaseService(this._db);

  // Products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    return await _db.query('products');
  }

  Future<Map<String, dynamic>?> getProduct(String id) async {
    final results = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    await _db.insert('products', product);
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    await _db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<void> deleteProduct(String id) async {
    await _db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Inventory Movements
  Future<List<Map<String, dynamic>>> getInventoryMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (productId != null) {
      whereClause += 'product_id = ?';
      whereArgs.add(productId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    return await _db.query(
      'inventory_movements',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );
  }

  Future<void> insertInventoryMovement(Map<String, dynamic> movement) async {
    await _db.insert('inventory_movements', movement);
  }

  // Users
  Future<Map<String, dynamic>?> getUser(String id) async {
    final results = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    await _db.insert('users', user);
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    await _db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  // Sync operations
  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    return await _db.query(
      'products',
      where: 'last_sync IS NULL OR updated_at > last_sync',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMovements() async {
    return await _db.query(
      'inventory_movements',
      where: 'last_sync IS NULL OR updated_at > last_sync',
    );
  }

  Future<void> markAsSynced(String table, String id) async {
    await _db.update(
      table,
      {'last_sync': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 