import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _categoryCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      cost: double.tryParse(_costCtrl.text.trim()) ?? 0,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
    );

    final ok = await context.read<ProductProvider>().addProduct(product);

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan produk')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Barcode (opsional)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(labelText: 'Harga Jual (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse((v ?? '').trim()) ?? -1) >= 0 ? null : 'Harga tidak valid',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costCtrl,
                        decoration: const InputDecoration(labelText: 'Harga Modal (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse((v ?? '').trim()) ?? -1) >= 0 ? null : 'Modal tidak valid',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stok'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse((v ?? '').trim()) ?? -1) >= 0 ? null : 'Stok tidak valid',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
