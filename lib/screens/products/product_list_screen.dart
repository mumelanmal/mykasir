import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  Future<void> _refresh() async {
    await context.read<ProductProvider>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau barcode…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.searchProducts('');
                        },
                      )
                    : null,
              ),
              onChanged: provider.searchProducts,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(provider.errorMessage!),
                            )
                          ],
                        )
                      : ListView.separated(
                          itemCount: provider.products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final Product p = provider.products[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                              ),
                              title: Text(p.name),
                              subtitle: Text('Stok: ${p.stock} • Harga: ${p.price.toStringAsFixed(0)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: p.id == null
                                    ? null
                                    : () async {
                                        final ok = await context.read<ProductProvider>().deleteProduct(p.id!);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ok ? 'Produk dihapus' : 'Gagal menghapus produk'),
                                          ),
                                        );
                                      },
                              ),
                              onTap: () {
                                // Placeholder for detail/edit in future
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (!context.mounted) return;
          if (created == true) {
            context.read<ProductProvider>().loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
