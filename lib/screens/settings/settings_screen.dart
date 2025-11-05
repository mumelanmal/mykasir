import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _taxCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _storeNameCtrl;
  late final TextEditingController _storeAddressCtrl;
  late final TextEditingController _storePhoneCtrl;
  bool _autoPrint = false;

  @override
  void initState() {
    super.initState();
    final sp = context.read<SettingsProvider>();
    _taxCtrl = TextEditingController(text: sp.defaultTaxRatePercent.toStringAsFixed(0));
    _discountCtrl = TextEditingController(text: sp.defaultDiscountRatePercent.toStringAsFixed(0));
    _storeNameCtrl = TextEditingController(text: sp.storeName);
    _storeAddressCtrl = TextEditingController(text: sp.storeAddress);
    _storePhoneCtrl = TextEditingController(text: sp.storePhone);
  _autoPrint = sp.autoPrintAfterSale;
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    _storeNameCtrl.dispose();
    _storeAddressCtrl.dispose();
    _storePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final sp = context.read<SettingsProvider>();
    final tax = double.tryParse(_taxCtrl.text.trim()) ?? 0;
    final disc = double.tryParse(_discountCtrl.text.trim()) ?? 0;
  final storeName = _storeNameCtrl.text.trim();
  final storeAddress = _storeAddressCtrl.text.trim();
  final storePhone = _storePhoneCtrl.text.trim();
  await sp.setStoreName(storeName);
    await sp.setStoreAddress(storeAddress);
    await sp.setStorePhone(storePhone);
    await sp.setDefaultTaxRatePercent(tax);
    await sp.setDefaultDiscountRatePercent(disc);
    await sp.setAutoPrintAfterSale(_autoPrint);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Identitas Toko'),
          const SizedBox(height: 8),
          TextField(
            controller: _storeNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Toko',
              hintText: 'mis. Toko Sumber Rejeki',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _storeAddressCtrl,
            decoration: const InputDecoration(
              labelText: 'Alamat Toko (opsional)',
              hintText: 'mis. Jl. Raya No. 123',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _storePhoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Telepon (opsional)',
              hintText: 'mis. 0812-3456-7890',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          // Printer
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Pengaturan Printer'),
              subtitle: Text(sp.btPrinterName ?? 'Belum dipilih'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/printer');
              },
            ),
          ),
          const SizedBox(height: 8),
          // Hapus pengaturan printer jaringan; hanya Bluetooth Classic digunakan
          const Text('Pajak & Diskon (Default)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pajak % (default)',
                    hintText: 'mis. 10',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diskon % (default)',
                    hintText: 'mis. 0',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pajak saat ini: ${sp.defaultTaxRatePercent.toStringAsFixed(0)}%'),
              Text('Diskon saat ini: ${sp.defaultDiscountRatePercent.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 16),
          if (!Platform.isAndroid && !Platform.isIOS) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cetak otomatis setelah transaksi'),
              subtitle: const Text('Desktop only - langsung print tanpa dialog'),
              value: _autoPrint,
              onChanged: (v) => setState(() => _autoPrint = v),
            ),
            const SizedBox(height: 16),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('Cetak otomatis'),
              subtitle: const Text('Di Android/iOS, system print dialog akan selalu muncul'),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Backup & Restore'),
            subtitle: Text('Cadangkan dan pulihkan data (segera hadir)'),
          ),
        ],
      ),
    );
  }
}

// (Dihapus) Form printer jaringan: kini hanya mendukung Bluetooth Classic
