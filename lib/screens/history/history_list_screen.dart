import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/transaction_service.dart';
import '../../services/bluetooth_classic_printer.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction.dart' as models;
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  final _svc = TransactionService();
  final _printer = BluetoothClassicPrinter();
  bool _loading = true;
  String? _error;
  List<models.Transaction> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    List<models.Transaction> list = const [];
    String? error;
    try {
      list = await _svc.getAllTransactions(limit: 100);
    } catch (e) {
      error = 'Gagal memuat riwayat: $e';
    }

    if (!mounted) return;
    setState(() {
      _items = list;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _reprint(models.Transaction tx) async {
    final sp = context.read<SettingsProvider>();
    final mac = sp.btPrinterId;
    if (mac == null || mac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih printer Bluetooth terlebih dahulu di menu Printer')), 
      );
      return;
    }

    // Ambil transaksi lengkap dengan items
    final full = await _svc.getTransactionById(tx.id!);
    if (full == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi tidak ditemukan')), 
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool ok = false;
    String? err;
    try {
      ok = await _printer.printTransaction(
        mac: mac,
        trx: full,
        storeName: sp.storeName,
        storeAddress: sp.storeAddress,
        storePhone: sp.storePhone,
        paperSize: sp.paperSize,
        charWidth: sp.receiptCharWidth,
      );
    } catch (e) {
      err = e.toString();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetak ulang terkirim')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cetak ulang${err != null ? ': $err' : ''}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text('MyKasir', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/transactions', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/history', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/products', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Staff'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/staff', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (ctx, i) {
                      final t = _items[i];
                      final date = DateFormatter.formatDateTime(t.transactionDate);
                      final total = CurrencyFormatter.format(t.total);
                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(t.transactionNumber),
                        subtitle: Text('$date  •  $total'),
                        trailing: IconButton(
                          tooltip: 'Cetak Ulang',
                          icon: const Icon(Icons.print),
                          onPressed: t.id == null ? null : () => _reprint(t),
                        ),
                        onTap: t.id == null ? null : () => _showDetail(t),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: _items.length,
                  ),
      ),
    );
  }

  Future<void> _showDetail(models.Transaction tx) async {
    // Optional simple detail dialog showing items
    final full = await _svc.getTransactionById(tx.id!);
    if (!mounted) return;
    if (full == null) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(full.transactionNumber, style: Theme.of(ctx).textTheme.titleMedium),
                Text(DateFormatter.formatDateTime(full.transactionDate), style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: full.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = full.items[i];
                      return ListTile(
                        dense: true,
                        title: Text(it.productName),
                        subtitle: Text('x${it.quantity}  •  ${CurrencyFormatter.format(it.price)}'),
                        trailing: Text(CurrencyFormatter.format(it.subtotal)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _reprint(full);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Ulang'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
