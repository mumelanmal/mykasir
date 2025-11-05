/// Deprecated BLE scanning service. Kept as a no-op stub after removing BLE dependency.
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._();
  BluetoothPrinterService._();
  factory BluetoothPrinterService() => _instance;

  Stream<bool> get isScanning => const Stream<bool>.empty();

  Stream<List<Object>> get scanResults => const Stream<List<Object>>.empty();

  Future<bool> ensurePermissions() async => true;

  Future<void> startScan({Duration timeout = const Duration(seconds: 6)}) async {}

  Future<void> stopScan() async {}

  Future<void> saveSelection(Object sp, Object r) async {}

  Future<bool> tryConnect(String deviceId) async => false;
}
