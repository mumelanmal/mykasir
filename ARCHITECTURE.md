# MyKasir - Aplikasi Kasir Sederhana

Aplikasi POS (Point of Sale) berbasis Flutter untuk mengelola produk, stok, staff, pencetakan struk, perhitungan pajak/diskon, laporan, dan backup/restore.

## 📱 Target Platform
- ✅ Android
- ✅ iOS  
- ✅ Linux
- ✅ macOS
- ✅ Windows
- ✅ Web

## 🏗️ Arsitektur Aplikasi

Proyek ini menggunakan **arsitektur berbasis fitur** (feature-based architecture) dengan pola **Provider** untuk state management.

### Struktur Folder

```
lib/
├── core/                      # Utilitas dan konfigurasi bersama
│   ├── constants/             # Konstanta aplikasi
│   │   └── app_constants.dart
│   ├── themes/                # Tema dan styling
│   │   └── app_theme.dart
│   └── utils/                 # Utility functions
│       ├── currency_formatter.dart
│       └── date_formatter.dart
│
├── models/                    # Data models
│   ├── product.dart          # Model Produk
│   ├── transaction.dart      # Model Transaksi & TransactionItem
│   └── staff.dart            # Model Staff/Karyawan
│
├── services/                  # Business logic & data access
│   ├── database_service.dart # SQLite database setup
│   ├── product_service.dart  # CRUD operations untuk produk
│   └── transaction_service.dart # CRUD operations untuk transaksi
│
├── providers/                 # State management (Provider pattern)
│   ├── product_provider.dart # State management untuk produk
│   └── transaction_provider.dart # State management untuk transaksi & keranjang
│
├── screens/                   # UI Screens
│   ├── home/                  # Home screen dengan menu utama
│   │   └── home_screen.dart
│   ├── products/              # Screens untuk manajemen produk
│   ├── transactions/          # Screens untuk transaksi penjualan
│   ├── staff/                 # Screens untuk manajemen staff
│   ├── reports/               # Screens untuk laporan penjualan
│   └── settings/              # Screens untuk pengaturan aplikasi
│
├── widgets/                   # Reusable UI components
│
└── main.dart                  # Entry point aplikasi
```

## 🎯 Fitur Utama

### 1. **Manajemen Produk**
- CRUD produk (tambah, edit, hapus, lihat)
- Pencarian produk berdasarkan nama atau barcode
- Tracking stok produk
- Notifikasi stok rendah
- Kategori produk
- Harga beli & harga jual

### 2. **Transaksi Penjualan**
- Keranjang belanja
- Scan barcode produk
- Diskon per item
- Diskon transaksi
- Perhitungan pajak
- Multiple metode pembayaran (Cash, Card, Transfer)
- Perhitungan kembalian otomatis

### 3. **Manajemen Staff**
- CRUD staff/karyawan
- Role management (Admin, Manager, Cashier)
- PIN login untuk kasir
- Tracking staff per transaksi

### 4. **Laporan & Reports**
- Laporan penjualan harian
- Laporan berdasarkan range tanggal
- Produk terlaris
- Visualisasi dengan chart (fl_chart)
- Export laporan

### 5. **Printer Integration**
- Cetak struk penjualan
- Support Bluetooth printer (ESC/POS)
- Generate PDF untuk email/preview
- Template struk yang dapat dikustomisasi

### 6. **Backup & Restore**
- Backup database ke file ZIP
- Restore dari backup
- Export/import data

## 🛠️ Tech Stack

### Framework & Language
- **Flutter** (>=3.0.0)
- **Dart** (>=2.17.0 <3.0.0)

### State Management
- **Provider** (^6.0.5) - Dependency injection & state management

### Local Storage
- **SQLite** (sqflite ^2.0.2+1) - Database utama untuk data transaksional
- **Hive** (^2.2.3) - NoSQL untuk settings/preferences
- **Shared Preferences** (^2.0.15) - Simple key-value storage

### Printing
- **printing** (^5.9.3) - PDF generation & print
- **esc_pos_utils** (^1.1.0) - ESC/POS command utilities
- **blue_thermal_printer** (^1.2.3) - Bluetooth thermal printer
- **flutter_blue_plus** (^1.32.0) - Bluetooth connectivity

### UI & Visualization
- **fl_chart** (^0.55.2) - Charts untuk laporan
- **Material Design** - UI framework
- **Inter Font** - Custom font family

### Utilities
- **intl** (^0.20.2) - Internationalization & formatting
- **path_provider** (^2.0.11) - File system paths
- **file_picker** (^5.2.5) - File picker untuk backup/restore
- **archive** (^3.3.5) - ZIP compression untuk backup

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0.0 atau lebih tinggi
- Dart SDK 2.17.0 atau lebih tinggi
- Android Studio / VS Code dengan Flutter extension
- Emulator Android atau perangkat fisik

### Installation

1. Clone repository
```bash
git clone <repository-url>
cd mykasir
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Development Commands

```bash
# Jalankan aplikasi
flutter run

# Jalankan dengan hot reload
flutter run

# Jalankan di device tertentu
flutter devices               # List devices
flutter run -d <device-id>

# Testing
flutter test                  # Run semua test
flutter test test/widget_test.dart  # Run test tertentu
flutter test --coverage       # Dengan coverage

# Code Quality
flutter analyze               # Analisis code
flutter format .              # Format code

# Build untuk production
flutter build apk             # Android APK
flutter build appbundle       # Android App Bundle
flutter build ios             # iOS (requires macOS)
flutter build web             # Web
flutter build linux           # Linux
flutter build macos           # macOS
flutter build windows         # Windows
```

## 📊 Database Schema

### Products Table
```sql
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
```

### Staff Table
```sql
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
```

### Transactions Table
```sql
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
  created_at TEXT NOT NULL
)
```

### Transaction Items Table
```sql
CREATE TABLE transaction_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  price REAL NOT NULL,
  quantity INTEGER NOT NULL,
  discount REAL DEFAULT 0,
  subtotal REAL NOT NULL
)
```

## 🔧 Configuration

### App Constants
File: `lib/core/constants/app_constants.dart`
- Database name & version
- Tax rates
- Currency settings
- Date/time formats
- Pagination settings

### Theme Customization
File: `lib/core/themes/app_theme.dart`
- Primary & secondary colors
- Typography (Inter font family)
- Card styles
- Input decoration theme

## 📝 Coding Conventions

### Dart Style Guide
- **Naming**: lowerCamelCase untuk variables/functions, UpperCamelCase untuk classes
- **Widgets**: Gunakan `const` constructor dimana memungkinkan untuk performance
- **Async**: Gunakan `async/await`, hindari `.then()` chains
- **Comments**: 
  - `///` untuk public API documentation
  - `//` untuk inline comments

### Provider Pattern
```dart
// 1. Create ChangeNotifier provider
class ProductProvider with ChangeNotifier {
  // State
  List<Product> _products = [];
  
  // Getters
  List<Product> get products => _products;
  
  // Methods yang mengubah state
  Future<void> loadProducts() async {
    _products = await _productService.getProducts();
    notifyListeners(); // Notify UI untuk rebuild
  }
}

// 2. Inject di main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProductProvider()),
  ],
  child: MaterialApp(...)
)

// 3. Consume di UI
Consumer<ProductProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.products.length,
      itemBuilder: (context, index) => ...
    );
  }
)
```

## 🐛 Common Issues

### Hot Reload Limitations
- Database schema changes memerlukan **hot restart**, bukan hot reload
- State Provider tidak reset dengan hot reload

### Bluetooth Printer
- Android 12+ memerlukan runtime permission untuk Bluetooth
- Test dengan hardware printer yang sebenarnya
- Tidak semua printer ESC/POS 100% compliant

### Platform Channels
- Jika implementasi native API, gunakan method channels
- Handle platform-specific code di masing-masing folder platform

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite Guide](https://pub.dev/packages/sqflite)
- [ESC/POS Printing](https://pub.dev/packages/esc_pos_utils)
- [FL Chart Examples](https://pub.dev/packages/fl_chart)

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

Developed with ❤️ using Flutter

---

**Version**: 0.1.0  
**Last Updated**: November 2025
