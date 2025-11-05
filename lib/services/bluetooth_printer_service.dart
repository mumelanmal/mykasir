// Deprecated BLE scanning helper.
// To keep the project minimal, BLE scanning was removed. This file remains
// as a tiny, well-documented stub to avoid breaking accidental imports.

class BluetoothPrinterService {
  const BluetoothPrinterService();

  /// No-op streams and methods. Use `BluetoothClassicPrinter` for actual
  /// Bluetooth Classic printing via platform channel.
  Stream<bool> get isScanning async* {}
  Stream<List<Object>> get scanResults async* {}
  Future<bool> ensurePermissions() async => true;
}
