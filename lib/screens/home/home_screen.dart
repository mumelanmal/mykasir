import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/transaction_service.dart';

/// Home screen dengan fokus ke Drawer untuk navigasi
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _txnService = TransactionService();
  bool _loading = true;
  String? _error;
  double _todaySales = 0;
  int _todayCount = 0;

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
    double sales = 0;
    int count = 0;
    String? error;
    try {
      sales = await _txnService.getTodaySales();
      count = await _txnService.getTodayTransactionCount();
    } catch (e) {
      error = 'Gagal memuat ringkasan: $e';
    }

    if (!mounted) return;
    setState(() {
      _todaySales = sales;
      _todayCount = count;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        elevation: 2,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Aplikasi kasir'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: const Text('Transaksi'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/transactions', (route) => false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Riwayat'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/history', (route) => false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: const Text('Produk'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/products', (route) => false);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Staff'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/staff', (route) => false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.assessment),
                      title: const Text('Laporan'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Pengaturan'),
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Ringkasan Hari Ini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              )
            else
              Row(
                children: [
                  Expanded(child: _InfoCard(label: 'Penjualan', value: 'Rp ${_todaySales.toStringAsFixed(0)}', color: Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _InfoCard(label: 'Transaksi', value: '$_todayCount', color: Colors.green)),
                ],
              ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Navigasi'),
                    SizedBox(height: 8),
                    Text('Gunakan tombol menu (☰) di kiri atas untuk membuka Drawer dan mengakses fitur.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
