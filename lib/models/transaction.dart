/// Model untuk Item Transaksi
class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double discount; // Diskon dalam rupiah
  final double subtotal;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.discount = 0,
    double? subtotal,
  }) : subtotal = subtotal ?? ((price * quantity) - discount);

  /// Convert dari Map (dari database)
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  /// Convert ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'discount': discount,
      'subtotal': subtotal,
    };
  }

  /// Copy dengan perubahan
  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    double? discount,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}

/// Model untuk Transaksi
class Transaction {
  final int? id;
  final String transactionNumber;
  final DateTime transactionDate;
  final int? staffId;
  final String? staffName;
  final double subtotal;
  final double discount; // Diskon transaksi (tambahan)
  final double tax;
  final double total;
  final double paid;
  final double change;
  final String paymentMethod; // 'cash', 'card', 'transfer'
  final String? notes;
  final List<TransactionItem> items;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.transactionNumber,
    DateTime? transactionDate,
    this.staffId,
    this.staffName,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    required this.paid,
    this.change = 0,
    this.paymentMethod = 'cash',
    this.notes,
    this.items = const [],
    DateTime? createdAt,
  })  : transactionDate = transactionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert dari Map (dari database)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      transactionNumber: map['transaction_number'] as String,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      staffId: map['staff_id'] as int?,
      staffName: map['staff_name'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      change: (map['change'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'staff_id': staffId,
      'staff_name': staffName,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid': paid,
      'change': change,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy dengan perubahan
  Transaction copyWith({
    int? id,
    String? transactionNumber,
    DateTime? transactionDate,
    int? staffId,
    String? staffName,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paid,
    double? change,
    String? paymentMethod,
    String? notes,
    List<TransactionItem>? items,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      change: change ?? this.change,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
