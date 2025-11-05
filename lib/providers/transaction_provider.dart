import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/product_service.dart';

/// Item keranjang belanja
class CartItem {
  final Product product;
  int quantity;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  double get subtotal => (product.price * quantity) - discount;
}

/// Provider untuk transaksi dan keranjang
class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final ProductService _productService = ProductService();

  final List<CartItem> _cartItems = [];
  double _transactionDiscount = 0;
  double _transactionTax = 0;
  String _paymentMethod = 'cash';
  String? _paymentChannel; // e.g., OVO, DANA for ewallet
  String? _notes;
  bool _isProcessing = false;
  String? _errorMessage;

  // Auto apply default tax/discount rates
  bool _autoApplyRates = false;
  double _defaultTaxPercent = 0;
  double _defaultDiscountPercent = 0;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  double get transactionDiscount => _transactionDiscount;
  double get transactionTax => _transactionTax;
  String get paymentMethod => _paymentMethod;
  String? get paymentChannel => _paymentChannel;
  String? get notes => _notes;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  /// Subtotal dari semua item
  double get subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Total setelah diskon dan pajak
  double get total {
    final afterDiscount = subtotal - _transactionDiscount;
    return afterDiscount + _transactionTax;
  }

  /// Jumlah total item di keranjang
  int get itemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Tambah produk ke keranjang
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    _recalculateAutoRatesIfNeeded();
    notifyListeners();
  }

  /// Kurangi quantity item
  void decreaseQuantity(int productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      _recalculateAutoRatesIfNeeded();
      notifyListeners();
    }
  }

  /// Update quantity item
  void updateQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity > 0) {
        _cartItems[index].quantity = quantity;
      } else {
        _cartItems.removeAt(index);
      }
      _recalculateAutoRatesIfNeeded();
      notifyListeners();
    }
  }

  /// Hapus item dari keranjang
  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _recalculateAutoRatesIfNeeded();
    notifyListeners();
  }

  /// Set diskon item
  void setItemDiscount(int productId, double discount) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index].discount = discount;
      _recalculateAutoRatesIfNeeded();
      notifyListeners();
    }
  }

  /// Set diskon transaksi
  void setTransactionDiscount(double discount) {
    _transactionDiscount = discount;
    notifyListeners();
  }

  /// Set pajak transaksi
  void setTransactionTax(double tax) {
    _transactionTax = tax;
    notifyListeners();
  }

  /// Set metode pembayaran
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Set payment channel/detail (e.g., E-Wallet provider)
  void setPaymentChannel(String? channel) {
    _paymentChannel = channel;
    notifyListeners();
  }

  /// Set catatan
  void setNotes(String? notes) {
    _notes = notes;
    notifyListeners();
  }

  /// Proses transaksi
  Future<Transaction?> processTransaction({
    required double paid,
    int? staffId,
    String? staffName,
  }) async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Keranjang kosong';
      notifyListeners();
      return null;
    }

    if (paid < total) {
      _errorMessage = 'Pembayaran kurang';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Buat transaksi
      // Compose method with channel for ewallet
      String composedMethod = _paymentMethod;
      if (_paymentMethod == 'ewallet' && (_paymentChannel != null && _paymentChannel!.isNotEmpty)) {
        composedMethod = 'ewallet:${_paymentChannel!}';
      }

      final transaction = Transaction(
        transactionNumber: _transactionService.generateTransactionNumber(),
        subtotal: subtotal,
        discount: _transactionDiscount,
        tax: _transactionTax,
        total: total,
        paid: paid,
        change: paid - total,
        paymentMethod: composedMethod,
        notes: _notes,
        staffId: staffId,
        staffName: staffName,
      );

      // Buat items
      final items = _cartItems.map((cartItem) {
        return TransactionItem(
          transactionId: 0, // Will be set by service
          productId: cartItem.product.id!,
          productName: cartItem.product.name,
          price: cartItem.product.price,
          quantity: cartItem.quantity,
          discount: cartItem.discount,
        );
      }).toList();

      // Simpan transaksi
      final transactionId =
          await _transactionService.insertTransaction(transaction, items);

      // Update stok produk
      for (final cartItem in _cartItems) {
        await _productService.reduceStock(
          cartItem.product.id!,
          cartItem.quantity,
        );
      }

      // Clear cart
      clearCart();

      // Return transaction with id
      return transaction.copyWith(id: transactionId, items: items);
    } catch (e) {
      _errorMessage = 'Gagal memproses transaksi: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear keranjang
  void clearCart() {
    _cartItems.clear();
    _transactionDiscount = 0;
    _transactionTax = 0;
    _paymentMethod = 'cash';
    _paymentChannel = null;
    _notes = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Aktifkan auto apply diskon/pajak default (dalam persen)
  void configureAutoRates({required double taxPercent, required double discountPercent, required bool enabled}) {
    _defaultTaxPercent = taxPercent;
    _defaultDiscountPercent = discountPercent;
    _autoApplyRates = enabled;
    _recalculateAutoRatesIfNeeded();
    notifyListeners();
  }

  void _recalculateAutoRatesIfNeeded() {
    if (!_autoApplyRates) return;
  final discountAmount = (subtotal * (_defaultDiscountPercent / 100)).clamp(0, double.infinity).toDouble();
  final taxBase = (subtotal - discountAmount).clamp(0, double.infinity).toDouble();
  final taxAmount = (taxBase * (_defaultTaxPercent / 100)).toDouble();
  _transactionDiscount = discountAmount;
  _transactionTax = taxAmount;
  }
}
