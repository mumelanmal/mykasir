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
    String? receiptFooter,
  }) async {
    final bytes = _buildEscPos(
      trx,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      paperSize: paperSize,
      charWidth: charWidth,
      receiptFooter: receiptFooter,
    );
    final ok = await _ch.invokeMethod('printBytes', {
      'mac': mac,
      'bytes': bytes,
    });
    return ok == true;
  }

  Future<bool> openConnection(String mac) async {
    try {
      final res = await _ch.invokeMethod('openConnection', {'mac': mac});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> closeConnection(String mac) async {
    try {
      final res = await _ch.invokeMethod('closeConnection', {'mac': mac});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isConnected(String mac) async {
    try {
      final res = await _ch.invokeMethod('isConnected', {'mac': mac});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Uint8List _buildEscPos(models.Transaction trx, {required String storeName, String storeAddress = '', String storePhone = '', String paperSize = '58mm', int? charWidth, String? receiptFooter}) {
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

    // payment method labels not needed in this template

    // Header (custom: centered store info, then separators and meta)
    cmd([0x1B, 0x61, 0x01]); // center
    cmd([0x1B, 0x45, 0x01]); // bold on
    text(_truncate((storeName.trim().isEmpty ? 'MyKasir' : storeName.trim()).toUpperCase(), width));
    cmd([0x1B, 0x45, 0x00]); // bold off
    if (storeAddress.trim().isNotEmpty) {
      text(_truncate(storeAddress.trim(), width));
    }
    if (storePhone.trim().isNotEmpty) {
      text(_truncate('Telp: $storePhone', width));
    }
    cmd([0x1B, 0x61, 0x00]); // left
    line();
    // add a blank line after the store header, then show date/kasir and separator
    text('');
  // Date and cashier (ensure Kasir label with colon is always printed; name may be empty)
  final kasirName = (trx.staffName != null && trx.staffName!.trim().isNotEmpty) ? trx.staffName!.trim() : '-';
  text('Tanggal : $dateStr');
  text(_truncate('Kasir : $kasirName', width));
  line();

    // Items (table: Name | Qty | Total)
    cmd([0x1B, 0x61, 0x00]); // left
    // compute column widths
    final int qtyW = width <= 34 ? 3 : 4;
    int totalW = (width * 0.25).round();
    if (totalW < 7) totalW = 7;
    final int nameW = width - qtyW - totalW - 2; // two spaces between columns

    String itemHeader() {
      final nm = 'Nama Barang';
      final qh = 'Qty';
      final th = 'Total';
      final left = nm.length > nameW ? nm.substring(0, nameW) : nm.padRight(nameW);
      final qpart = qh.padLeft(qtyW);
      final tpart = th.padLeft(totalW);
      return '$left  $qpart$tpart';
    }

    text(itemHeader());
    line();
    for (final it in trx.items) {
      final totalStr = money(it.subtotal, withSymbol: false);
      final qtyStr = it.quantity.toString();
      final wrapped = _wrap(it.productName, nameW);
      for (int i = 0; i < wrapped.length; i++) {
        final part = wrapped[i];
        if (i < wrapped.length - 1) {
          // intermediate line just the name
          text(part);
        } else {
          // last line: name + qty + total
          final left = part.length > nameW ? part.substring(0, nameW) : part.padRight(nameW);
          final qpart = qtyStr.padLeft(qtyW);
          final tpart = totalStr.padLeft(totalW);
          text('$left  $qpart$tpart');
        }
      }
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
  _kv(b, 'TOTAL', money(trx.total), bold: true, width: width, fillChar: '.');
  _kv(b, 'Tunai', money(trx.paid), width: width, fillChar: '.');
  _kv(b, 'Kembali', money(trx.change), width: width, fillChar: '.');

    // Footer & cut
    // add a blank line before footer so footer doesn't stick to totals
    text('');
  cmd([0x1B, 0x61, 0x01]); // center
    if (receiptFooter != null && receiptFooter.trim().isNotEmpty) {
      final lines = receiptFooter.split('\n');
      for (final l in lines) {
        text(_truncate(l.trim(), width));
      }
    } else {
      text('Terima Kasih :)');
      text('Barang yang sudah dibeli');
      text('tidak dapat dikembalikan');
    }
    cmd([0x1B, 0x64, 0x03]); // feed 3
    cmd([0x1D, 0x56, 0x41, 0x10]); // full cut

    return b.takeBytes();
  }

  void _kv(BytesBuilder b, String k, String v, {bool bold = false, int width = 32, String fillChar = ' '}) {
    if (bold) {
      b.add([0x1B, 0x45, 0x01]);
    }
    final line = _padKV(k, v, width: width, fillChar: fillChar);
  b.add(utf8.encode('$line\n'));
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

  // old column formatter removed; using table layout instead

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
    return '${s.substring(0, width - 3)}...';
  }
}
