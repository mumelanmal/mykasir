// Network printing removed to keep the codebase minimal. This minimal stub
// remains for compatibility; it intentionally does nothing.

class NetworkPrinterService {
  const NetworkPrinterService();

  Future<void> printReceipt({
    required String host,
    required int port,
    required Object trx,
    required String storeName,
  }) async {
    // No-op
    return;
  }
}
