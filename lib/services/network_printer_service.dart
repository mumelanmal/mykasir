import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/transaction.dart' as models;

/// Minimal ESC/POS helper for network printers (raw TCP 9100)
class NetworkPrinterService {
  const NetworkPrinterService();

  // ESC/POS commands
  static const List<int> _init = [0x1B, 0x40];
  static const List<int> _alignLeft = [0x1B, 0x61, 0];
  static const List<int> _alignCenter = [0x1B, 0x61, 1];
  static const List<int> _alignRight = [0x1B, 0x61, 2];
  static const List<int> _boldOn = [0x1B, 0x45, 1];
  static const List<int> _boldOff = [0x1B, 0x45, 0];
  // static const List<int> _smallOn = [0x1B, 0x4D, 1];
  static const List<int> _smallOff = [0x1B, 0x4D, 0];
  static const List<int> _cutFull = [0x1D, 0x56, 0x41, 0x10];

  Future<void> printReceipt({
    required String host,
    required int port,
    required models.Transaction trx,
    required String storeName,
  }) async {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    final builder = BytesBuilder();

    void text(String s, {bool bold = false, String align = 'left'}) {
      switch (align) {
        case 'center': builder.add(_alignCenter); break;
        case 'right': builder.add(_alignRight); break;
        default: builder.add(_alignLeft); break;
      }
      if (bold) builder.add(_boldOn); else builder.add(_boldOff);
      // Most printers expect CP437/CP936/etc; fallback to basic latin
      builder.add(utf8.encode(s));
      builder.add([0x0A]); // LF
    }

    void kv(String k, String v, {bool bold = false}) {
      builder.add(_alignLeft);
      if (bold) builder.add(_boldOn); else builder.add(_boldOff);
      final line = _padKV(k, v, width: 32);
      builder.add(utf8.encode(line));
      builder.add([0x0A]);
    }

    builder.add(_init);
  builder.add(_smallOff);

    // Header
    builder.add(_alignCenter);
    builder.add(_boldOn);
    text(storeName, bold: true, align: 'center');
    builder.add(_boldOff);
    text('No: ${trx.transactionNumber}', align: 'center');
    text('Tanggal: ${trx.transactionDate}');
    text('--------------------------------');

    // Items
    for (final it in trx.items) {
      text(it.productName);
      final qty = it.quantity.toString();
      final price = it.price.toStringAsFixed(0);
      final sub = it.subtotal.toStringAsFixed(0);
      final line = _padColumns([qty, price, sub], [4, 9, 9]);
      text(line, align: 'right');
    }
    text('--------------------------------');
    kv('Subtotal', 'Rp ${trx.subtotal.toStringAsFixed(0)}');
    kv('Diskon', 'Rp ${trx.discount.toStringAsFixed(0)}');
    kv('Pajak', 'Rp ${trx.tax.toStringAsFixed(0)}');
    kv('Total', 'Rp ${trx.total.toStringAsFixed(0)}', bold: true);
    kv('Dibayar', 'Rp ${trx.paid.toStringAsFixed(0)}');
    kv('Kembali', 'Rp ${trx.change.toStringAsFixed(0)}');

    // Footer
    builder.add(_alignCenter);
    text('Terima kasih');

    // Feed and cut
    builder.add([0x1B, 0x64, 0x04]); // print and feed 4 lines
    builder.add(_cutFull);

    socket.add(builder.takeBytes());
    await socket.flush();
    await socket.close();
  }

  String _padKV(String k, String v, {int width = 32}) {
    final left = k;
    final right = v;
    final spaces = width - left.length - right.length;
    final pad = spaces > 0 ? ' ' * spaces : ' ';
    return '$left$pad$right';
  }

  String _padColumns(List<String> cols, List<int> widths) {
    final parts = <String>[];
    for (var i = 0; i < cols.length; i++) {
      final s = cols[i];
      final w = widths[i];
      if (s.length >= w) {
        parts.add(s.substring(0, w));
      } else {
        parts.add(s.padLeft(w));
      }
    }
    return parts.join(' ');
  }
}
