import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';

/// Provider untuk pengaturan aplikasi (disimpan di Hive)
class SettingsProvider extends ChangeNotifier {
  static const _kTaxRateKey = 'defaultTaxRatePercent';
  static const _kDiscountRateKey = 'defaultDiscountRatePercent';
  static const _kPrinterNameKey = 'defaultPrinterName';
  static const _kPrinterUrlKey = 'defaultPrinterUrl';
  static const _kAutoPrintKey = 'autoPrintAfterSale';
  static const _kBtPrinterNameKey = 'btPrinterName';
  static const _kBtPrinterIdKey = 'btPrinterId';
  static const _kStoreNameKey = 'storeName';
  static const _kStoreAddressKey = 'storeAddress';
  static const _kStorePhoneKey = 'storePhone';
  static const _kPaperSizeKey = 'paperSize'; // '58mm' | '80mm'
  static const _kReceiptWidthKey = 'receiptCharWidth'; // e.g., 32, 42, 48
  static const _kReceiptFooterKey = 'receiptFooter';
  static const _kLoggedInStaffIdKey = 'loggedInStaffId';

  final Box _box = Hive.box(AppConstants.settingsBox);

  double _defaultTaxRatePercent = 0;
  double _defaultDiscountRatePercent = 0;
  String? _defaultPrinterName;
  String? _defaultPrinterUrl;
  bool _autoPrintAfterSale = false;
  String? _btPrinterName;
  String? _btPrinterId;
  String _storeName = 'MyKasir';
  String _storeAddress = '';
  String _storePhone = '';
  String _paperSize = '58mm';
  int _receiptCharWidth = 32;
  String _receiptFooter = 'Terima Kasih :)\nBarang yang sudah dibeli\ntidak dapat dikembalikan';
  int? _loggedInStaffId;

  double get defaultTaxRatePercent => _defaultTaxRatePercent;
  double get defaultDiscountRatePercent => _defaultDiscountRatePercent;
  String? get defaultPrinterName => _defaultPrinterName;
  String? get defaultPrinterUrl => _defaultPrinterUrl;
  bool get autoPrintAfterSale => _autoPrintAfterSale;
  String? get btPrinterName => _btPrinterName;
  String? get btPrinterId => _btPrinterId;
  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  String get paperSize => _paperSize; // '58mm' or '80mm'
  int get receiptCharWidth => _receiptCharWidth;
  String get receiptFooter => _receiptFooter;
  int? get loggedInStaffId => _loggedInStaffId;

  SettingsProvider() {
    _load();
  }

  void _load() {
    _defaultTaxRatePercent = (_box.get(_kTaxRateKey) as num?)?.toDouble() ?? 0;
    _defaultDiscountRatePercent = (_box.get(_kDiscountRateKey) as num?)?.toDouble() ?? 0;
    _defaultPrinterName = _box.get(_kPrinterNameKey) as String?;
    _defaultPrinterUrl = _box.get(_kPrinterUrlKey) as String?;
    _autoPrintAfterSale = (_box.get(_kAutoPrintKey) as bool?) ?? false;
    _btPrinterName = _box.get(_kBtPrinterNameKey) as String?;
    _btPrinterId = _box.get(_kBtPrinterIdKey) as String?;
  _storeName = (_box.get(_kStoreNameKey) as String?)?.trim().isNotEmpty == true
    ? (_box.get(_kStoreNameKey) as String)
    : 'MyKasir';
    _storeAddress = (_box.get(_kStoreAddressKey) as String?) ?? '';
    _storePhone = (_box.get(_kStorePhoneKey) as String?) ?? '';
    final ps = _box.get(_kPaperSizeKey) as String?;
    _paperSize = (ps == '80mm') ? '80mm' : '58mm';
    // default char width depends on paper size
    final savedWidth = _box.get(_kReceiptWidthKey) as int?;
    if (savedWidth != null && savedWidth > 0) {
      _receiptCharWidth = savedWidth;
    } else {
      _receiptCharWidth = _paperSize == '80mm' ? 42 : 32;
    }
    _receiptFooter = (_box.get(_kReceiptFooterKey) as String?) ?? _receiptFooter;
    _loggedInStaffId = _box.get(_kLoggedInStaffIdKey) as int?;
  }

  Future<void> setDefaultTaxRatePercent(double value) async {
    _defaultTaxRatePercent = value;
    await _box.put(_kTaxRateKey, value);
    notifyListeners();
  }

  Future<void> setDefaultDiscountRatePercent(double value) async {
    _defaultDiscountRatePercent = value;
    await _box.put(_kDiscountRateKey, value);
    notifyListeners();
  }

  Future<void> setDefaultPrinter(String name, String url) async {
    _defaultPrinterName = name;
    _defaultPrinterUrl = url;
    await _box.put(_kPrinterNameKey, name);
    await _box.put(_kPrinterUrlKey, url);
    notifyListeners();
  }

  Future<void> setAutoPrintAfterSale(bool enabled) async {
    _autoPrintAfterSale = enabled;
    await _box.put(_kAutoPrintKey, enabled);
    notifyListeners();
  }

  Future<void> setBluetoothPrinter({required String name, required String id}) async {
    _btPrinterName = name;
    _btPrinterId = id;
    await _box.put(_kBtPrinterNameKey, name);
    await _box.put(_kBtPrinterIdKey, id);
    notifyListeners();
  }

  Future<void> clearBluetoothPrinter() async {
    _btPrinterName = null;
    _btPrinterId = null;
    await _box.delete(_kBtPrinterNameKey);
    await _box.delete(_kBtPrinterIdKey);
    notifyListeners();
  }

  Future<void> setStoreName(String value) async {
    _storeName = value.trim().isEmpty ? 'MyKasir' : value.trim();
    await _box.put(_kStoreNameKey, _storeName);
    notifyListeners();
  }

  Future<void> setStoreAddress(String value) async {
    _storeAddress = value.trim();
    await _box.put(_kStoreAddressKey, _storeAddress);
    notifyListeners();
  }

  Future<void> setStorePhone(String value) async {
    _storePhone = value.trim();
    await _box.put(_kStorePhoneKey, _storePhone);
    notifyListeners();
  }

  Future<void> setPaperSize(String value) async {
    // normalize
    final v = (value == '80mm') ? '80mm' : '58mm';
    _paperSize = v;
    await _box.put(_kPaperSizeKey, _paperSize);
    // Adjust default width when switching paper size if width not compatible
    if (_paperSize == '80mm' && _receiptCharWidth < 40) {
      _receiptCharWidth = 42;
      await _box.put(_kReceiptWidthKey, _receiptCharWidth);
    }
    if (_paperSize == '58mm' && _receiptCharWidth > 40) {
      _receiptCharWidth = 32;
      await _box.put(_kReceiptWidthKey, _receiptCharWidth);
    }
    notifyListeners();
  }

  Future<void> setReceiptCharWidth(int width) async {
    if (width <= 0) return;
    _receiptCharWidth = width;
    await _box.put(_kReceiptWidthKey, _receiptCharWidth);
    notifyListeners();
  }

  Future<void> setReceiptFooter(String value) async {
    _receiptFooter = value.trim();
    await _box.put(_kReceiptFooterKey, _receiptFooter);
    notifyListeners();
  }

  Future<void> setLoggedInStaffId(int? id) async {
    _loggedInStaffId = id;
    if (id == null) {
      await _box.delete(_kLoggedInStaffIdKey);
    } else {
      await _box.put(_kLoggedInStaffIdKey, id);
    }
    notifyListeners();
  }

  // Network printer settings removed: only Bluetooth Classic supported
}
