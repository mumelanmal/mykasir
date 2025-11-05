import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility untuk format tanggal dan waktu
class DateFormatter {
  static final DateFormat _dateFormatter = DateFormat(AppConstants.dateFormat);
  static final DateFormat _timeFormatter = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormatter = DateFormat(AppConstants.dateTimeFormat);

  /// Format DateTime menjadi string tanggal (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format DateTime menjadi string waktu (HH:mm)
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }

  /// Format DateTime menjadi string tanggal dan waktu (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  /// Parse string tanggal menjadi DateTime
  static DateTime? parseDate(String dateStr) {
    try {
      return _dateFormatter.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Parse string tanggal-waktu menjadi DateTime
  static DateTime? parseDateTime(String dateTimeStr) {
    try {
      return _dateTimeFormatter.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }

  /// Dapatkan string tanggal hari ini
  static String today() {
    return formatDate(DateTime.now());
  }

  /// Dapatkan string waktu sekarang
  static String now() {
    return formatTime(DateTime.now());
  }

  /// Dapatkan string tanggal-waktu sekarang
  static String currentDateTime() {
    return formatDateTime(DateTime.now());
  }
}
