/// Model untuk Staff/Karyawan
class Staff {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String role; // 'admin', 'cashier', 'manager'
  final String? pin; // PIN untuk login kasir
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Staff({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.role = 'cashier',
    this.pin,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert dari Map (dari database)
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      role: map['role'] as String? ?? 'cashier',
      pin: map['pin'] as String?,
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
      'phone': phone,
      'email': email,
      'address': address,
      'role': role,
      'pin': pin,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy dengan perubahan
  Staff copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? role,
    String? pin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Cek apakah staff adalah admin
  bool get isAdmin => role == 'admin';

  /// Cek apakah staff adalah manager
  bool get isManager => role == 'manager';

  /// Cek apakah staff adalah kasir
  bool get isCashier => role == 'cashier';
}
