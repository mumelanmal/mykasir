import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../models/transaction.dart' as models;
import '../../services/bluetooth_classic_printer.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class PrinterSettingsScreen extends StatelessWidget {
  const PrinterSettingsScreen({super.key});

  // Hanya Bluetooth Classic dipertahankan

  // Buat transaksi dummy kecil untuk test network print
  models.Transaction _fakeTrx() {
    final now = DateTime.now();
    return models.Transaction(
      id: 0,
      transactionNumber: 'TEST-${now.millisecondsSinceEpoch % 100000}',
      transactionDate: now,
      items: [
        models.TransactionItem(transactionId: 0, productId: 0, productName: 'Test Item', price: 1000, quantity: 1),
      ],
      subtotal: 1000,
      discount: 0,
      tax: 0,
      total: 1000,
      paid: 1000,
      paymentMethod: 'cash',
      change: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
  // Only Bluetooth Classic printing is supported now
    
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Printer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ukuran Kertas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('58 mm'),
                selected: sp.paperSize == '58mm',
                onSelected: (v) {
                  if (v) context.read<SettingsProvider>().setPaperSize('58mm');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('80 mm'),
                selected: sp.paperSize == '80mm',
                onSelected: (v) {
                  if (v) context.read<SettingsProvider>().setPaperSize('80mm');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sp.paperSize == '80mm')
            Row(
              children: [
                const Text('Lebar Karakter:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('42'),
                  selected: sp.receiptCharWidth == 42,
                  onSelected: (v) {
                    if (v) context.read<SettingsProvider>().setReceiptCharWidth(42);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('48'),
                  selected: sp.receiptCharWidth == 48,
                  onSelected: (v) {
                    if (v) context.read<SettingsProvider>().setReceiptCharWidth(48);
                  },
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Lebar karakter: 32 (58mm)', style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
          Text('Preview Struk (${sp.paperSize})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Builder(
            builder: (_) {
              final width = sp.receiptCharWidth;
              final trx = _fakeTrx();
              final lines = _buildPreview(trx, sp.storeName, sp.storeAddress, sp.storePhone, width);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  lines.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.2),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Hanya tombol cetak test Bluetooth
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final sp = context.read<SettingsProvider>();
              final mac = sp.btPrinterId;
              if (mac == null || mac.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih perangkat Bluetooth di atas dulu')));
                return;
              }
              try {
                final ok = await BluetoothClassicPrinter().printTransaction(
                  mac: mac,
                  trx: _fakeTrx(),
                  storeName: sp.storeName,
                  storeAddress: sp.storeAddress,
                  storePhone: sp.storePhone,
                  paperSize: sp.paperSize,
                  charWidth: sp.receiptCharWidth,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Test print BT terkirim' : 'Gagal print BT')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal print BT: $e')));
              }
            },
            icon: const Icon(Icons.bluetooth_connected),
            label: const Text('Cetak Test (Bluetooth)'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.bluetooth, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Printer Bluetooth', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) {
              final savedName = sp.btPrinterName;
              final savedId = sp.btPrinterId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(savedName ?? 'Belum dipilih'),
                subtitle: Text(savedId ?? '-'),
                trailing: savedId == null
                    ? null
                    : TextButton.icon(
                        onPressed: () => sp.clearBluetoothPrinter(),
                        icon: const Icon(Icons.clear),
                        label: const Text('Hapus'),
                      ),
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await BluetoothClassicPrinter().ensurePermissions();
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin Bluetooth diberikan')));
                  (context as Element).markNeedsBuild();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin Bluetooth ditolak. Aktifkan di pengaturan aplikasi.')));
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang Perangkat Terhubung'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, String>>>(
            future: BluetoothClassicPrinter().getBondedDevices(),
            builder: (context, snap) {
              final bonded = snap.data ?? const [];
              if (bonded.isEmpty) {
                return const Text('Belum ada perangkat terhubung. Hubungkan printer via Pengaturan Bluetooth OS.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Perangkat Terhubung (Bluetooth Classic):'),
                  const SizedBox(height: 8),
                  ...bonded.map((d) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(d['name'] ?? 'Perangkat'),
                          subtitle: Text(d['mac'] ?? ''),
                          trailing: TextButton(
                            onPressed: () async {
                              final name = d['name'] ?? 'Perangkat';
                              final id = d['mac'] ?? '';
                              await sp.setBluetoothPrinter(name: name, id: id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tersimpan: $name')),
                              );
                            },
                            child: const Text('Pilih'),
                          ),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> _buildPreview(models.Transaction trx, String storeName, String storeAddress, String storePhone, int width) {
    final lines = <String>[];
    String money(num n, {bool withSymbol = true}) => withSymbol
        ? CurrencyFormatter.format(n)
        : CurrencyFormatter.formatWithoutSymbol(n);
    String line([String ch = '-' ]) => List.filled(width, ch).join();
    String center(String s) {
      if (s.length >= width) return s.substring(0, width);
      final pad = (width - s.length) ~/ 2;
      return ' ' * pad + s;
    }
    String truncate(String s) => s.length <= width ? s : s.substring(0, width);
    String padKV(String k, String v, {String fillChar = ' '}) {
      final availableForK = width - v.length - 1; // at least one fill
      final kk = availableForK <= 0 ? '' : (k.length > availableForK ? k.substring(0, availableForK) : k);
      final fillCount = width - kk.length - v.length;
      final pad = (fillCount > 0 ? List.filled(fillCount, fillChar).join() : fillChar);
      return '$kk$pad$v';
    }
    List<String> wrap(String text) {
      if (text.length <= width) return [text];
      final out = <String>[];
      var remaining = text.trim();
      while (remaining.isNotEmpty) {
        if (remaining.length <= width) { out.add(remaining); break; }
        final cut = remaining.substring(0, width);
        final idx = cut.lastIndexOf(' ');
        if (idx > 0) {
          out.add(cut.substring(0, idx));
          remaining = remaining.substring(idx + 1).trimLeft();
        } else {
          out.add(cut);
          remaining = remaining.substring(width);
        }
      }
      return out;
    }

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
    lines.add(center((storeName.trim().isEmpty ? 'MyKasir' : storeName.trim())));
    if (storeAddress.trim().isNotEmpty) {
      lines.add(center(truncate(storeAddress.trim())));
    }
    if (storePhone.trim().isNotEmpty) {
      lines.add(center(truncate(storePhone.trim())));
    }
    lines.add(center('STRUK PEMBELIAN'));
    lines.add(''); // blank line after title
    lines.add('No: ${trx.transactionNumber}');
    lines.add('Tanggal: ${DateFormatter.formatDateTime(trx.transactionDate)}');
    if ((trx.staffName ?? '').isNotEmpty) {
      lines.add(padKV('Kasir: ${trx.staffName}', 'Metode: ${pmPretty(trx.paymentMethod)}'));
    } else {
      lines.add(padKV('Metode: ${pmPretty(trx.paymentMethod)}', ''));
    }
    lines.add(line());

    // Items
    String itemRow(String qty, String price, String subtotal) {
      const int spaces = 2;
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

    for (final it in trx.items) {
      lines.addAll(wrap(it.productName));
      lines.add(itemRow(
        it.quantity.toString(),
        money(it.price, withSymbol: true),
        money(it.subtotal, withSymbol: false),
      ));
    }

    // Totals
    lines.add(line());
    final totalQty = trx.items.fold<int>(0, (sum, it) => sum + it.quantity);
    lines.add(padKV('Jumlah item', totalQty.toString()));
    lines.add(padKV('Subtotal', money(trx.subtotal), fillChar: '.'));
    if (trx.discount != 0) {
      final disc = trx.discount > 0 ? '- ${money(trx.discount)}' : money(trx.discount);
      lines.add(padKV('Diskon', disc, fillChar: '.'));
    }
    if (trx.tax != 0) {
      lines.add(padKV('Pajak', money(trx.tax), fillChar: '.'));
    }
    lines.add(line('='));
    lines.add(padKV('Total', money(trx.total), fillChar: '.'));
    lines.add(padKV('Dibayar', money(trx.paid), fillChar: '.'));
    lines.add(padKV('Kembali', money(trx.change), fillChar: '.'));

    // Footer
    lines.add(center('Terima kasih'));

    return lines;
  }
}
