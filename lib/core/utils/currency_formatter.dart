import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility untuk format mata uang
class CurrencyFormatter {
  // Use decimal pattern and attach symbol manually to avoid non-breaking spaces
  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  /// Format angka menjadi format mata uang (Rp 10.000)
  static String format(num amount) {
    final digits = _decimal.format(amount);
    // Ensure a normal space after symbol (avoid NBSP from some locales)
    return '${AppConstants.currencySymbol} $digits';
  }

  /// Format angka menjadi format mata uang tanpa simbol (10.000)
  static String formatWithoutSymbol(num amount) {
    return _decimal.format(amount);
  }

  /// Parse string mata uang menjadi angka
  static double parse(String value) {
    // Hapus semua karakter non-digit kecuali titik dan koma
    final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '');
    // Replace koma dengan titik untuk parsing
    final normalizedValue = cleanValue.replaceAll(',', '.');
    return double.tryParse(normalizedValue) ?? 0.0;
  }
}
