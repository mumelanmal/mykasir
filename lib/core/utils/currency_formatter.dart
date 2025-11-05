import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility untuk format mata uang
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  /// Format angka menjadi format mata uang (Rp 10.000)
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format angka menjadi format mata uang tanpa simbol (10.000)
  static String formatWithoutSymbol(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
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
