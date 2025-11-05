import '../models/product.dart';
import 'database_service.dart';

/// Service untuk operasi CRUD Product
class ProductService {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Dapatkan semua produk
  Future<List<Product>> getAllProducts() async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Dapatkan produk aktif
  Future<List<Product>> getActiveProducts() async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Dapatkan produk berdasarkan ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  /// Cari produk berdasarkan barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      where: 'barcode = ? AND is_active = ?',
      whereArgs: [barcode, 1],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  /// Cari produk berdasarkan kata kunci
  Future<List<Product>> searchProducts(String keyword) async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      where: '(name LIKE ? OR barcode LIKE ?) AND is_active = ?',
      whereArgs: ['%$keyword%', '%$keyword%', 1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Tambah produk baru
  Future<int> insertProduct(Product product) async {
    final db = await _dbService.database;
    return await db.insert('products', product.toMap());
  }

  /// Update produk
  Future<int> updateProduct(Product product) async {
    final db = await _dbService.database;
    final updatedProduct = product.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'products',
      updatedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Hapus produk (soft delete - set is_active = 0)
  Future<int> deleteProduct(int id) async {
    final db = await _dbService.database;
    return await db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus produk permanen
  Future<int> deleteProductPermanent(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update stok produk
  Future<int> updateStock(int productId, int newStock) async {
    final db = await _dbService.database;
    return await db.update(
      'products',
      {
        'stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  /// Kurangi stok produk (saat transaksi)
  Future<bool> reduceStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null || product.stock < quantity) {
      return false;
    }
    final newStock = product.stock - quantity;
    await updateStock(productId, newStock);
    return true;
  }

  /// Dapatkan produk dengan stok rendah (< 10)
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    final db = await _dbService.database;
    final result = await db.query(
      'products',
      where: 'stock < ? AND is_active = ?',
      whereArgs: [threshold, 1],
      orderBy: 'stock ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }
}
