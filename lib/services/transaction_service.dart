import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/transaction.dart' as models;
import 'database_service.dart';

/// Service untuk operasi CRUD Transaction
class TransactionService {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Generate nomor transaksi unik
  String generateTransactionNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }

  /// Simpan transaksi baru dengan items
  Future<int> insertTransaction(
      models.Transaction transaction, List<models.TransactionItem> items) async {
    final db = await _dbService.database;
    int transactionId = 0;

    // Gunakan transaksi database untuk atomicity
    await db.transaction((txn) async {
      // Insert transaksi
      transactionId = await txn.insert('transactions', transaction.toMap());

      // Insert items
      for (final item in items) {
        await txn.insert(
          'transaction_items',
          item.copyWith(transactionId: transactionId).toMap(),
        );
      }
    });

    return transactionId;
  }

  /// Dapatkan semua transaksi
  Future<List<models.Transaction>> getAllTransactions({int? limit}) async {
    final db = await _dbService.database;
    final result = await db.query(
      'transactions',
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Dapatkan transaksi berdasarkan ID dengan items
  Future<models.Transaction?> getTransactionById(int id) async {
    final db = await _dbService.database;

    // Dapatkan transaksi
    final txnResult = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (txnResult.isEmpty) return null;

    final transaction = models.Transaction.fromMap(txnResult.first);

    // Dapatkan items
    final itemsResult = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );

    final items = itemsResult.map((map) => models.TransactionItem.fromMap(map)).toList();

    return transaction.copyWith(items: items);
  }

  /// Dapatkan transaksi berdasarkan tanggal
  Future<List<models.Transaction>> getTransactionsByDate(DateTime date) async {
    final db = await _dbService.database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'transaction_date DESC',
    );

    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Dapatkan transaksi berdasarkan range tanggal
  Future<List<models.Transaction>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await _dbService.database;
    final result = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'transaction_date DESC',
    );

    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Dapatkan total penjualan hari ini
  Future<double> getTodaySales() async {
    final db = await _dbService.database;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(total) as total_sales
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return (result.first['total_sales'] as num?)?.toDouble() ?? 0.0;
  }

  /// Dapatkan jumlah transaksi hari ini
  Future<int> getTodayTransactionCount() async {
    final db = await _dbService.database;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  /// Dapatkan laporan penjualan berdasarkan range tanggal
  Future<Map<String, dynamic>> getSalesReport(
      DateTime startDate, DateTime endDate) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as transaction_count,
        SUM(total) as total_sales,
        SUM(discount) as total_discount,
        SUM(tax) as total_tax,
        AVG(total) as average_transaction
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final data = result.first;
    return {
      'transaction_count': data['transaction_count'] as int? ?? 0,
      'total_sales': (data['total_sales'] as num?)?.toDouble() ?? 0.0,
      'total_discount': (data['total_discount'] as num?)?.toDouble() ?? 0.0,
      'total_tax': (data['total_tax'] as num?)?.toDouble() ?? 0.0,
      'average_transaction':
          (data['average_transaction'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Dapatkan produk terlaris
  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      {int limit = 10, DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbService.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause =
          'WHERE t.transaction_date >= ? AND t.transaction_date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT 
        ti.product_id,
        ti.product_name,
        SUM(ti.quantity) as total_quantity,
        SUM(ti.subtotal) as total_sales
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      $whereClause
      GROUP BY ti.product_id, ti.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [...whereArgs, limit]);

    return result;
  }

  /// Dapatkan total penjualan per kategori produk pada rentang tanggal
  Future<List<Map<String, dynamic>>> getSalesByCategory(
      {DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbService.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause =
          'WHERE t.transaction_date >= ? AND t.transaction_date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT 
        p.category as category,
        SUM(ti.subtotal) as total_sales
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      INNER JOIN products p ON ti.product_id = p.id
      $whereClause
      GROUP BY p.category
      ORDER BY total_sales DESC
    ''', whereArgs);

    return result.map((row) => {
          'category': row['category'] ?? 'Lainnya',
          'total_sales': (row['total_sales'] as num?)?.toDouble() ?? 0.0,
        }).toList();
  }
}
