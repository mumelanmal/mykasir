import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../models/transaction.dart' as models;
import '../../services/bluetooth_classic_printer.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
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
    // Connection state is queried on-demand with FutureBuilder/buttons below.

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
              final lines = _buildPreview(trx, sp.storeName, sp.storeAddress, sp.storePhone, width, sp.receiptFooter);
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
              final messenger = ScaffoldMessenger.of(context);
              final mac = sp.btPrinterId;
              if (mac == null || mac.isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('Pilih perangkat Bluetooth di atas dulu')));
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
                    receiptFooter: sp.receiptFooter,
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(ok ? 'Test print BT terkirim' : 'Gagal print BT')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Gagal print BT: $e')));
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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top line: name and address (MAC)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            savedName ?? 'Belum dipilih',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (savedId != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              savedId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bottom line: connection icon + actions (only when an ID exists)
                    if (savedId != null)
                      Row(
                        children: [
                          FutureBuilder<bool>(
                            future: BluetoothClassicPrinter().isConnected(savedId),
                            builder: (c, snap) {
                              final connected = snap.data == true;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                                  color: connected ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final mac = savedId;
                              // Try connect
                              messenger.showSnackBar(const SnackBar(content: Text('Mencoba sambungkan...')));
                              final ok = await BluetoothClassicPrinter().openConnection(mac);
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text(ok ? 'Terhubung' : 'Gagal terhubung')));
                              setState(() {});
                            },
                            icon: const Icon(Icons.bluetooth),
                            label: const Text('Connect'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final mac = savedId;
                              final ok = await BluetoothClassicPrinter().closeConnection(mac);
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text(ok ? 'Terputus' : 'Gagal putus')));
                              setState(() {});
                            },
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect'),
                          ),
                          TextButton.icon(
                            onPressed: () => sp.clearBluetoothPrinter(),
                            icon: const Icon(Icons.clear),
                            label: const Text('Hapus'),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await BluetoothClassicPrinter().ensurePermissions();
                if (!mounted) return;
                if (ok) {
                  messenger.showSnackBar(const SnackBar(content: Text('Izin Bluetooth diberikan')));
                  setState(() {});
                } else {
                  messenger.showSnackBar(const SnackBar(content: Text('Izin Bluetooth ditolak. Aktifkan di pengaturan aplikasi.')));
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
                                            final messenger = ScaffoldMessenger.of(context);
                                            final name = d['name'] ?? 'Perangkat';
                                            final id = d['mac'] ?? '';
                                            await sp.setBluetoothPrinter(name: name, id: id);
                                            if (!mounted) return;
                                            messenger.showSnackBar(
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

  List<String> _buildPreview(models.Transaction trx, String storeName, String storeAddress, String storePhone, int width, String receiptFooter) {
    final lines = <String>[];
    String money(num n) => CurrencyFormatter.formatWithoutSymbol(n);
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

    // Header
    lines.add(center((storeName.trim().isEmpty ? 'MyKasir' : storeName.trim()).toUpperCase()));
    if (storeAddress.trim().isNotEmpty) {
      lines.add(center(truncate(storeAddress.trim())));
    }
    if (storePhone.trim().isNotEmpty) {
      lines.add(center('Telp: $storePhone'));
    }
    // blank line after store header
    lines.add('');
    // separator line (moved to be after the blank line)
    lines.add(line());
  final kasirName = (trx.staffName != null && trx.staffName!.trim().isNotEmpty) ? trx.staffName!.trim() : '-';
  lines.add('Tanggal : ${DateFormatter.formatDateTime(trx.transactionDate)}');
  lines.add(truncate('Kasir : $kasirName'));
    lines.add(line());

    // Items header
    final int qtyW = width <= 34 ? 3 : 4;
    int totalW = (width * 0.25).round();
    if (totalW < 7) totalW = 7;
    final int nameW = width - qtyW - totalW - 2;
    String itemHeader() {
      final nm = 'Nama Barang';
      final qh = 'Qty';
      final th = 'Total';
      final left = nm.length > nameW ? nm.substring(0, nameW) : nm.padRight(nameW);
      final qpart = qh.padLeft(qtyW);
      final tpart = th.padLeft(totalW);
      return '$left  $qpart$tpart';
    }
    lines.add(itemHeader());
    lines.add(line());

    for (final it in trx.items) {
      final totalStr = money(it.subtotal);
      final qtyStr = it.quantity.toString();
      final wrapped = <String>[];
      var remaining = it.productName.trim();
      while (remaining.isNotEmpty) {
        if (remaining.length <= nameW) { wrapped.add(remaining); break; }
        final cut = remaining.substring(0, nameW);
        final idx = cut.lastIndexOf(' ');
        if (idx > 0) {
          wrapped.add(cut.substring(0, idx));
          remaining = remaining.substring(idx + 1).trimLeft();
        } else {
          wrapped.add(cut);
          remaining = remaining.substring(nameW);
        }
      }
      for (int i = 0; i < wrapped.length; i++) {
        final part = wrapped[i];
        if (i < wrapped.length - 1) {
          lines.add(part);
        } else {
          final left = part.length > nameW ? part.substring(0, nameW) : part.padRight(nameW);
          final qpart = qtyStr.padLeft(qtyW);
          final tpart = totalStr.padLeft(totalW);
          lines.add('$left  $qpart$tpart');
        }
      }
    }

  lines.add(line());
    lines.add(padKV('Subtotal', CurrencyFormatter.formatWithoutSymbol(trx.subtotal), fillChar: '.'));
    if (trx.discount != 0) {
      final disc = trx.discount > 0 ? '- ${CurrencyFormatter.formatWithoutSymbol(trx.discount)}' : CurrencyFormatter.formatWithoutSymbol(trx.discount);
      lines.add(padKV('Diskon', disc, fillChar: '.'));
    }
    lines.add(line('='));
    lines.add(padKV('TOTAL', CurrencyFormatter.formatWithoutSymbol(trx.total), fillChar: '.'));
    lines.add(padKV('Tunai', CurrencyFormatter.formatWithoutSymbol(trx.paid), fillChar: '.'));
    lines.add(padKV('Kembali', CurrencyFormatter.formatWithoutSymbol(trx.change), fillChar: '.'));
  // Add a blank line before footer so it doesn't stick to totals
  lines.add('');

  // Footer
  if (receiptFooter.trim().isNotEmpty) {
      for (final l in receiptFooter.split('\n')) {
        lines.add(center(truncate(l.trim())));
      }
    } else {
      lines.add(center('Terima Kasih :)'));
      lines.add(center('Barang yang sudah dibeli'));
      lines.add(center('tidak dapat dikembalikan'));
    }

    return lines;
  }
}
