import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Provider untuk manajemen state Product
class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _categoryFilter; // null = all

  // Getters
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;

  /// List kategori unik dari produk aktif
  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      final c = p.category?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Load semua produk
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getActiveProducts();
  _filteredProducts = _products;
  _applyFilters();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cari produk
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set kategori
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    Iterable<Product> list = _products;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false));
    }
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      final c = _categoryFilter!;
      list = list.where((p) => (p.category ?? '') == c);
    }
    _filteredProducts = list.toList();
  }

  /// Tambah produk
  Future<bool> addProduct(Product product) async {
    try {
      await _productService.insertProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah produk: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update produk
  Future<bool> updateProduct(Product product) async {
    try {
      await _productService.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate produk: $e';
      notifyListeners();
      return false;
    }
  }

  /// Hapus produk
  Future<bool> deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus produk: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update stok produk
  Future<bool> updateStock(int productId, int newStock) async {
    try {
      await _productService.updateStock(productId, newStock);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate stok: $e';
      notifyListeners();
      return false;
    }
  }

  /// Dapatkan produk dengan stok rendah
  Future<List<Product>> getLowStockProducts() async {
    try {
      return await _productService.getLowStockProducts();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk stok rendah: $e';
      notifyListeners();
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
