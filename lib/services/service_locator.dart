import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:inventory_control/services/database/database_service.dart';
import 'package:inventory_control/services/auth/auth_service.dart';
import 'package:inventory_control/services/sync/sync_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final SharedPreferences _prefs;
  late final Database _database;
  late final DatabaseService databaseService;
  late final AuthService authService;
  late final SyncService syncService;

  static ServiceLocator get instance => _instance;
}

Future<void> setupServiceLocator() async {
  final instance = ServiceLocator.instance;
  
  // Initialize SharedPreferences
  instance._prefs = await SharedPreferences.getInstance();
  
  // Initialize SQLite database
  if (kIsWeb) {
    // Use FFI implementation for web
    databaseFactory = databaseFactoryFfiWeb;
  }

  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'inventory.db');
  
  instance._database = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      // Create tables
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          role TEXT NOT NULL,
          last_login INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          sku TEXT NOT NULL,
          barcode TEXT,
          category TEXT NOT NULL,
          current_quantity REAL NOT NULL,
          min_stock_level REAL NOT NULL,
          max_stock_level REAL NOT NULL,
          unit_of_measurement TEXT NOT NULL,
          cost_price REAL,
          selling_price REAL,
          image_url TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_sync INTEGER
        )
      ''');
      
      await db.execute('''
        CREATE TABLE inventory_movements (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity REAL NOT NULL,
          date INTEGER NOT NULL,
          reason TEXT NOT NULL,
          reference TEXT,
          notes TEXT,
          created_by TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_sync INTEGER,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (created_by) REFERENCES users (id)
        )
      ''');
    },
  );

  // Initialize services
  instance.databaseService = DatabaseService(instance._database);
  instance.authService = AuthService(instance._prefs);
  instance.syncService = SyncService(
    instance.databaseService,
    instance.authService,
  );
} 