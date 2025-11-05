import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// PDF export removed to align with Bluetooth-only printing focus
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../services/transaction_service.dart';
import '../../models/transaction.dart' as models;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = TransactionService();
  DateTimeRange? _range;
  bool _loading = true;
  String? _error;

  // Aggregates
  int _transactionCount = 0;
  double _totalSales = 0;
  double _totalDiscount = 0;
  double _totalTax = 0;
  double _averageTransaction = 0;
  List<models.Transaction> _transactions = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _salesByCategory = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
      final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);

      final report = await _service.getSalesReport(start, end);
      final txns = await _service.getTransactionsByDateRange(start, end);
      final tops = await _service.getTopSellingProducts(limit: 8, startDate: start, endDate: end);
      final cats = await _service.getSalesByCategory(startDate: start, endDate: end);
      setState(() {
        _transactionCount = (report['transaction_count'] as num).toInt();
        _totalSales = (report['total_sales'] as num).toDouble();
        _totalDiscount = (report['total_discount'] as num).toDouble();
        _totalTax = (report['total_tax'] as num).toDouble();
        _averageTransaction = (report['average_transaction'] as num).toDouble();
        _transactions = txns;
        _topProducts = tops;
        _salesByCategory = cats;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat laporan: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<DateTime, double> _groupByDay(List<models.Transaction> txns) {
    final map = <DateTime, double>{};
    for (final t in txns) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      map[d] = (map[d] ?? 0) + t.total;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dayTotals = _groupByDay(_transactions);
    final dates = <DateTime>[];
    if (_range != null) {
      DateTime d = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
      final last = DateTime(_range!.end.year, _range!.end.month, _range!.end.day);
      while (!d.isAfter(last)) {
        dates.add(d);
        d = d.add(const Duration(days: 1));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.table_view),
            onPressed: _loading || _error != null ? null : _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                initialDateRange: _range,
              );
              if (picked != null) {
                setState(() => _range = picked);
                await _load();
              }
            },
          ),
        ],
      ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoChip(label: 'Transaksi', value: _transactionCount.toString()),
                        _InfoChip(label: 'Total Penjualan', value: 'Rp ${_totalSales.toStringAsFixed(0)}'),
                        _InfoChip(label: 'Total Diskon', value: 'Rp ${_totalDiscount.toStringAsFixed(0)}'),
                        _InfoChip(label: 'Total Pajak', value: 'Rp ${_totalTax.toStringAsFixed(0)}'),
                        _InfoChip(label: 'Rata2 Transaksi', value: 'Rp ${_averageTransaction.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              spots: [
                                for (int i = 0; i < dates.length; i++)
                                  FlSpot(i.toDouble(), (dayTotals[dates[i]] ?? 0).toDouble()),
                              ],
                            )
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (dates.length / 6).clamp(1, 6).toDouble(),
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                                  final d = dates[idx];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text('${d.day}/${d.month}'),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Top Produk', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          barGroups: [
                            for (int i = 0; i < _topProducts.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (_topProducts[i]['total_quantity'] as num?)?.toDouble() ?? 0,
                                    width: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= _topProducts.length) return const SizedBox.shrink();
                                  final name = (_topProducts[idx]['product_name'] ?? '') as String;
                                  return SizedBox(
                                    width: 56,
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Penjualan per Kategori', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      child: _salesByCategory.isEmpty
                          ? const Center(child: Text('Tidak ada data'))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  for (int i = 0; i < _salesByCategory.length; i++)
                                    PieChartSectionData(
                                      title: (_salesByCategory[i]['category'] ?? 'Lainnya') as String,
                                      value: (_salesByCategory[i]['total_sales'] as num?)?.toDouble() ?? 0,
                                      color: Colors.primaries[i % Colors.primaries.length],
                                      radius: 70,
                                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final buf = StringBuffer();
      buf.writeln('Laporan ${_range!.start} - ${_range!.end}');
      buf.writeln('transaction_count,total_sales,total_discount,total_tax,average_transaction');
      buf.writeln('$_transactionCount,$_totalSales,$_totalDiscount,$_totalTax,$_averageTransaction');
      buf.writeln();
      buf.writeln('Top Produk');
      buf.writeln('product_id,product_name,total_quantity,total_sales');
      for (final p in _topProducts) {
        buf.writeln('${p['product_id']},"${p['product_name']}",${p['total_quantity']},${p['total_sales']}');
      }
      buf.writeln();
      buf.writeln('Penjualan per Kategori');
      buf.writeln('category,total_sales');
      for (final c in _salesByCategory) {
        buf.writeln('"${c['category']}",${c['total_sales']}');
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buf.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV disimpan: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export CSV: $e')),
      );
    }
  }

  // PDF export removed
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

