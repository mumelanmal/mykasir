import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../core/constants/app_constants.dart';

/// Service untuk manajemen database SQLite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Dapatkan instance database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  /// Inisialisasi database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, filePath);

    return await openDatabase(
      dbFilePath,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Buat tabel-tabel database
  Future<void> _createDB(Database db, int version) async {
    // Tabel Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        cost REAL DEFAULT 0,
        stock INTEGER DEFAULT 0,
        category TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Staff
    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        role TEXT DEFAULT 'cashier',
        pin TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL UNIQUE,
        transaction_date TEXT NOT NULL,
        staff_id INTEGER,
        staff_name TEXT,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL,
        paid REAL NOT NULL,
        change REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (staff_id) REFERENCES staff (id)
      )
    ''');

    // Tabel Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Index untuk performa
    await db.execute(
        'CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(transaction_date)');
    await db.execute(
        'CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id)');
  }

  /// Upgrade database (untuk versi mendatang)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Implementasi migration di sini jika ada perubahan schema
    // Contoh:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE products ADD COLUMN new_field TEXT');
    // }
  }

  /// Tutup database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Reset database (untuk testing atau reset data)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, AppConstants.databaseName);
    await deleteDatabase(dbFilePath);
    _database = null;
  }
}
