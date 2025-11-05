/// Konstanta aplikasi MyKasir
class AppConstants {
  // App Info
  static const String appName = 'MyKasir';
  static const String appVersion = '0.1.0';

  // Database
  static const String databaseName = 'mykasir.db';
  static const int databaseVersion = 1;

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String preferencesBox = 'preferences';

  // Tax & Discount
  static const double defaultTaxRate = 0.0; // 0% default
  static const double maxDiscountPercent = 100.0;

  // Currency
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';

  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Backup
  static const String backupFileExtension = '.zip';
  static const String backupDateFormat = 'yyyyMMdd_HHmmss';
}
