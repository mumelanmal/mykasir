import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/transaction.dart' as models;
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';

class BluetoothClassicPrinter {
  static const MethodChannel _ch = MethodChannel('mykasir/bluetooth');

  Future<List<Map<String, String>>> getBondedDevices() async {
    final dynamic res = await _ch.invokeMethod('getBondedDevices');
    final list = (res as List).cast<Map<dynamic, dynamic>>();
    return list
        .map((e) => {
              'name': e['name']?.toString() ?? 'Perangkat',
              'mac': e['mac']?.toString() ?? '',
            })
        .toList();
  }

  /// Request runtime Bluetooth permissions on Android (BLUETOOTH_CONNECT/SCAN).
  /// Returns true if permissions are granted (or not required on older Android).
  Future<bool> ensurePermissions() async {
    try {
      final res = await _ch.invokeMethod('ensurePermissions');
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printTransaction({
    required String mac,
    required models.Transaction trx,
    required String storeName,
    String storeAddress = '',
    String storePhone = '',
    String paperSize = '58mm', // '58mm' or '80mm'
    int? charWidth,
  }) async {
    final bytes = _buildEscPos(
      trx,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      paperSize: paperSize,
      charWidth: charWidth,
    );
    final ok = await _ch.invokeMethod('printBytes', {
      'mac': mac,
      'bytes': bytes,
    });
    return ok == true;
  }

  Uint8List _buildEscPos(models.Transaction trx, {required String storeName, String storeAddress = '', String storePhone = '', String paperSize = '58mm', int? charWidth}) {
    // Typical widths: 58mm -> ~32 chars, 80mm -> ~42 or 48 chars (Font A)
    final int width = charWidth ?? ((paperSize == '80mm') ? 42 : 32);

    final b = BytesBuilder();
    void cmd(List<int> c) => b.add(c);
    void text(String s) => b.add(utf8.encode('$s\n'));
  void line([String ch = '-']) => text(List.filled(width, ch).join());

    String money(num n, {bool withSymbol = true}) {
      return withSymbol ? CurrencyFormatter.format(n) : CurrencyFormatter.formatWithoutSymbol(n);
    }

    String dateStr = DateFormatter.formatDateTime(trx.transactionDate);

    // ESC/POS basics
    cmd([0x1B, 0x40]); // init

    String pmLabel(String pm) {
      switch (pm) {
        case 'cash':
          return 'Tunai';
        case 'ewallet':
          return 'E-Wallet';
        case 'qris':
          return 'QRIS';
        case 'debit':
          return 'Debit';
        case 'transfer':
          return 'Transfer';
        default:
          return pm;
      }
    }
    String pmPretty(String method) {
      if (method.startsWith('ewallet:')) {
        final p = method.split(':').elementAt(1);
        return 'E-Wallet ($p)';
      }
      return pmLabel(method);
    }

    // Header
    cmd([0x1B, 0x61, 0x01]); // center
    cmd([0x1B, 0x45, 0x01]); // bold on
    text(_truncate(storeName.trim().isEmpty ? 'MyKasir' : storeName.trim(), width));
    cmd([0x1B, 0x45, 0x00]); // bold off
    if (storeAddress.trim().isNotEmpty) {
      text(_truncate(storeAddress.trim(), width));
    }
    if (storePhone.trim().isNotEmpty) {
      text(_truncate(storePhone.trim(), width));
    }
    cmd([0x1B, 0x45, 0x01]); // bold on
    text('STRUK PEMBELIAN');
    cmd([0x1B, 0x45, 0x00]); // bold off
    text(''); // blank line after title
    cmd([0x1B, 0x61, 0x00]); // left
    text('No: ${trx.transactionNumber}');
    text('Tanggal: $dateStr');
    if ((trx.staffName ?? '').isNotEmpty) {
      text(_padKV('Kasir: ${trx.staffName}', 'Metode: ${pmPretty(trx.paymentMethod)}', width: width));
    } else {
      text(_padKV('Metode: ${pmPretty(trx.paymentMethod)}', '', width: width));
    }
    line();

    // Items
    cmd([0x1B, 0x61, 0x00]); // left
    for (final it in trx.items) {
      // Name (wrapped to width)
  final wrapped = _wrap(it.productName, width);
      for (final w in wrapped) {
        text(w);
      }
      // Row with aligned columns: [qty] [price] [subtotal]
      final line = _formatItemRow(
        qty: it.quantity.toString(),
        price: money(it.price, withSymbol: true),
        subtotal: money(it.subtotal, withSymbol: false),
        width: width,
      );
      text(line);
    }

    line();
    final totalQty = trx.items.fold<int>(0, (sum, it) => sum + it.quantity);
    text(_padKV('Jumlah item', totalQty.toString(), width: width));
    _kv(b, 'Subtotal', money(trx.subtotal), width: width, fillChar: '.');
    if (trx.discount != 0) {
      final disc = trx.discount > 0 ? '- ${money(trx.discount)}' : money(trx.discount);
      _kv(b, 'Diskon', disc, width: width, fillChar: '.');
    }
    if (trx.tax != 0) {
      _kv(b, 'Pajak', money(trx.tax), width: width, fillChar: '.');
    }
    line('=');
    _kv(b, 'Total', money(trx.total), bold: true, width: width, fillChar: '.');
    _kv(b, 'Dibayar', money(trx.paid), width: width, fillChar: '.');
    _kv(b, 'Kembali', money(trx.change), width: width, fillChar: '.');

    // Footer & cut
    cmd([0x1B, 0x61, 0x01]); // center
    text('Terima kasih');
    cmd([0x1B, 0x64, 0x03]); // feed 3
    cmd([0x1D, 0x56, 0x41, 0x10]); // full cut

    return b.takeBytes();
  }

  void _kv(BytesBuilder b, String k, String v, {bool bold = false, int width = 32, String fillChar = ' '}) {
    if (bold) {
      b.add([0x1B, 0x45, 0x01]);
    }
    final line = _padKV(k, v, width: width, fillChar: fillChar);
    b.add(utf8.encode(line + '\n'));
    if (bold) {
      b.add([0x1B, 0x45, 0x00]);
    }
  }

  String _padKV(String k, String v, {int width = 32, String fillChar = ' '}) {
    // Trim left label if needed so right value can be perfectly right-aligned.
    final availableForK = width - v.length - 1; // reserve at least one fill
    final kk = availableForK <= 0
        ? ''
        : (k.length > availableForK ? k.substring(0, availableForK) : k);
    final fillCount = width - kk.length - v.length;
    final pad = (fillCount > 0
            ? List.filled(fillCount, fillChar).join()
            : fillChar);
    return '$kk$pad$v';
  }

  String _formatItemRow({required String qty, required String price, required String subtotal, required int width}) {
    // Dynamic column widths to support 42/48/etc.
    const int spaces = 2; // spaces between columns (1 each)
    final int qtyW = width <= 34 ? 4 : 5;
    int priceW = ((width - qtyW - spaces) * 0.28).round();
    if (priceW < 9) priceW = 9;
    int subtotalW = width - qtyW - priceW - spaces;
    if (subtotalW < 10) {
      final need = 10 - subtotalW;
      priceW = (priceW - need).clamp(7, priceW);
      subtotalW = width - qtyW - priceW - spaces;
    }
    String right(String s, int w) => s.length > w ? s.substring(s.length - w) : s.padLeft(w);
    return [right(qty, qtyW), right(price, priceW), right(subtotal, subtotalW)].join(' ');
  }

  // Removed old column formatter (no longer used)

  List<String> _wrap(String text, int width) {
    if (text.length <= width) return [text];
    final lines = <String>[];
    var remaining = text.trim();
    while (remaining.isNotEmpty) {
      if (remaining.length <= width) {
        lines.add(remaining);
        break;
      }
      // try to break at last space within width
      final cut = remaining.substring(0, width);
      final idx = cut.lastIndexOf(' ');
      if (idx > 0) {
        lines.add(cut.substring(0, idx));
        remaining = remaining.substring(idx + 1).trimLeft();
      } else {
        lines.add(cut);
        remaining = remaining.substring(width);
      }
    }
    return lines;
  }

  String _truncate(String s, int width) {
    if (s.length <= width) return s;
    if (width <= 3) return s.substring(0, width);
    return s.substring(0, width - 3) + '...';
  }
}
