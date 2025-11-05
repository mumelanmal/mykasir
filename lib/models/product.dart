/// Model untuk Produk
class Product {
  final int? id;
  final String name;
  final String? description;
  final String? barcode;
  final double price;
  final double cost; // Harga modal
  final int stock;
  final String? category;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    this.barcode,
    required this.price,
    this.cost = 0,
    this.stock = 0,
    this.category,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert dari Map (dari database)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      stock: map['stock'] as int? ?? 0,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy dengan perubahan
  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? cost,
    int? stock,
    String? category,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Hitung profit margin
  double get profitMargin {
    if (cost == 0) return 0;
    return ((price - cost) / cost) * 100;
  }

  /// Hitung profit per unit
  double get profitPerUnit {
    return price - cost;
  }
}
