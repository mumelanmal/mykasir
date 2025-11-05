# MyKasir - AI Coding Agent Instructions

## Project Overview
MyKasir is a Flutter-based POS (Point of Sale) application for managing products, stock, staff, printing receipts, tax/discount calculations, reports, and backup/restore functionality. This is an early-stage project currently at the scaffolding phase with boilerplate Flutter code.

**App Name:** mykasir  
**Description:** Aplikasi kasir sederhana (Simple cashier application)  
**Target Platforms:** Android, iOS, Linux, macOS, Windows, Web

## Technology Stack

### Core Framework
- **Flutter SDK:** >=3.0.0
- **Dart SDK:** >=2.17.0 <3.0.0
- **State Management:** Provider (v6.0.5)
- **Linting:** flutter_lints (v2.0.0) with standard Flutter lint rules

### Key Dependencies
- **Local Storage:** sqflite (SQLite database), hive (NoSQL), shared_preferences, path_provider
- **Printing:** printing (PDF generation), esc_pos_utils, blue_thermal_printer, flutter_blue (Bluetooth connectivity)
- **UI/Visualization:** fl_chart (charts for reports), Material Design
- **Data Management:** file_picker, archive (for backup/restore)
- **Formatting:** intl (internationalization/date formatting)
- **Fonts:** Inter (custom font family in `assets/fonts/`)

## Project Structure (Implemented)

```
lib/
├── core/                      # Shared utilities and configuration
│   ├── constants/
│   │   └── app_constants.dart
│   ├── themes/
│   │   └── app_theme.dart
│   └── utils/
│       ├── currency_formatter.dart
│       └── date_formatter.dart
├── models/                    # Data models
│   ├── product.dart
│   ├── transaction.dart
│   └── staff.dart
├── services/                  # Business logic & data access
│   ├── database_service.dart
│   ├── product_service.dart
│   └── transaction_service.dart
├── providers/                 # State management (Provider pattern)
│   ├── product_provider.dart
│   └── transaction_provider.dart
├── screens/                   # UI Screens (feature-based)
│   ├── home/
│   │   └── home_screen.dart
│   ├── products/
│   ├── transactions/
│   ├── staff/
│   ├── reports/
│   └── settings/
├── widgets/                   # Reusable UI components
└── main.dart                  # Entry point with Provider setup

test/
  widget_test.dart    # Basic widget test

assets/
  images/             # Image assets
  printer/            # Printer-related assets
  fonts/              # Inter font files (needs Inter-Regular.ttf)
```

**Current State:** Architecture is fully implemented with Provider pattern, database services, models, and basic home screen. Ready for feature development.

## Development Workflows

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter devices          # List available devices
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code (following Dart style guide)
flutter format .

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

### Building for Production
```bash
# Android APK
flutter build apk

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS (requires macOS)
flutter build ios

# Web
flutter build web

# Desktop (platform-specific)
flutter build linux    # On Linux
flutter build macos    # On macOS
flutter build windows  # On Windows
```

## Architectural Guidelines

### Implemented Architecture

1. **Feature-Based Organization:**
   - ✅ `core/` - Constants, themes, and utilities are implemented
   - ✅ `models/` - Product, Transaction, TransactionItem, Staff models with full CRUD support
   - ✅ `providers/` - ProductProvider and TransactionProvider with ChangeNotifier
   - ✅ `services/` - DatabaseService, ProductService, TransactionService fully implemented
   - ⏳ `screens/` - Home screen done, feature screens need implementation
   - ⏳ `widgets/` - Common widgets to be created as needed

2. **State Management Pattern (Implemented):**
   - Provider pattern fully set up in `main.dart` with MultiProvider
   - ProductProvider manages product state with CRUD operations and search
   - TransactionProvider manages cart, transactions, and payment processing
   - All providers use `notifyListeners()` to update UI
   - Error handling with user-friendly messages

3. **Database Design (Implemented):**
   - SQLite database with 4 tables: products, staff, transactions, transaction_items
   - Database versioning and migration support in DatabaseService
   - Indexes on barcode, transaction_date for performance
   - Foreign key constraints with cascade delete
   - Hive boxes initialized for settings and preferences
   - Repository pattern in service layer (ProductService, TransactionService)

4. **Key Implementation Details:**
   - **Models:** All models have fromMap/toMap, copyWith methods
   - **Services:** CRUD operations, search, filtering, reporting queries
   - **Providers:** Shopping cart logic, stock management, transaction processing
   - **Utilities:** CurrencyFormatter (Rp format), DateFormatter (dd/MM/yyyy)
   - **Theme:** Material 3 with custom colors, Inter font, consistent styling

5. **Printer Integration (Ready for Implementation):**
   - Dependencies installed: printing, esc_pos_utils, blue_thermal_printer, flutter_blue_plus
   - Template storage location: `assets/printer/`
   - Transaction model includes all data needed for receipt printing

### Code Conventions
- **Naming:** Follow Dart naming conventions (lowerCamelCase for variables/functions, UpperCamelCase for classes)
- **Widgets:** Prefer const constructors where possible for performance
- **Async:** Use async/await for asynchronous operations, avoid `.then()` chains
- **Comments:** Use `///` for public API documentation, `//` for inline comments
- **Localization:** Use Indonesian as primary language with English support via intl package

## Platform-Specific Notes

### Android
- **Package:** com.example.mykasir (needs to be changed for production)
- **Min SDK:** Defined by Flutter (check `flutter.minSdkVersion`)
- **Build System:** Gradle with Kotlin DSL (.gradle.kts)
- **Permissions:** Will need Bluetooth, Storage, and Internet permissions for printer connectivity

### iOS
- **Bundle ID:** Needs configuration in `ios/Runner/Info.plist`
- **Bluetooth:** Requires NSBluetoothAlwaysUsageDescription in Info.plist

### Desktop (Linux/macOS/Windows)
- CMake-based build system
- Currently has default runner configurations

### Web
- PWA-ready with manifest.json
- Limited printer support (use PDF generation via printing package)

## Critical Implementation Notes

1. **Database Migrations:** When implementing sqflite, create a versioned schema with migration logic
2. **Offline-First:** Design for offline operation; sync to cloud is not currently in dependencies
3. **Receipt Printing:** Test ESC/POS commands with actual hardware; thermal printers have varying ESC/POS compliance
4. **Backup/Restore:** Use archive package to create ZIP backups of SQLite database + any local files
5. **Reports:** Use fl_chart for daily/monthly sales visualizations; aggregate data efficiently from transactions
6. **Tax/Discount:** Store as percentages or fixed amounts in database; apply at transaction level

## Testing Strategy
- Write widget tests for all screens (see `test/widget_test.dart` as template)
- Create integration tests for complete transaction flows
- Mock printer services for testing without hardware
- Test database migrations with sample data

## Common Pitfalls
- **Hot Reload Limitations:** Database schema changes require hot restart, not just hot reload
- **Printer Connectivity:** Bluetooth permissions must be requested at runtime on Android 12+
- **Provider Scope:** Ensure providers are placed above MaterialApp in widget tree
- **Platform Channels:** If implementing native printer APIs, remember to handle platform-specific code in method channels

## Getting Started for AI Agents

### Current Implementation Status
✅ **Completed:**
- Core architecture (constants, themes, utils)
- Data models (Product, Transaction, Staff)
- Database services (SQLite setup with migrations)
- Business logic services (ProductService, TransactionService)
- State management (ProductProvider, TransactionProvider)
- Home screen with navigation menu

⏳ **Need Implementation:**
- Product management screens (list, add, edit, search)
- Transaction/checkout screen with cart UI
- Staff management screens
- Reports screen with charts (fl_chart)
- Settings screen (printer config, tax rates, backup/restore)
- Printer service integration
- Barcode scanning integration

### Development Workflow
1. **Read existing code first:** Check models, services, providers before creating new features
2. **Follow established patterns:**
   - Create screen in `lib/screens/<feature>/`
   - Use existing providers via `Consumer<ProviderName>` or `context.watch<ProviderName>()`
   - Call service methods through providers, not directly
3. **Use MCP Dart SDK tools:** Prefer `mcp_dart_sdk_mcp__*` tools over shell commands
4. **Testing:** Run `flutter test` after changes, update tests as needed
5. **Code quality:** Run `flutter analyze` and `flutter format .` before commits

### Quick Reference
- **Run app:** `flutter run` (uses web by default on Linux)
- **Add product:** Implement in `lib/screens/products/product_form_screen.dart`
- **Transaction flow:** Cart (TransactionProvider) → Payment → Receipt Print
- **Database queries:** See `transaction_service.dart` for report examples
- **Formatting:** Use `CurrencyFormatter.format()` and `DateFormatter.formatDate()`

## Resources
- Flutter docs: https://docs.flutter.dev/
- Provider package: https://pub.dev/packages/provider
- Sqflite guide: https://pub.dev/packages/sqflite
- ESC/POS printing: https://pub.dev/packages/esc_pos_utils
