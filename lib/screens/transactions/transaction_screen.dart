import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/staff.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/staff_provider.dart';
import '../../services/bluetooth_classic_printer.dart';
import '../../core/utils/currency_formatter.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _taxCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      // Terapkan default pajak/diskon dari pengaturan (otomatis)
      final sp = context.read<SettingsProvider>();
      context.read<TransactionProvider>().configureAutoRates(
            taxPercent: sp.defaultTaxRatePercent,
            discountPercent: sp.defaultDiscountRatePercent,
            enabled: true,
          );
    });
  }

  void _addToCart(Product p) {
    context.read<TransactionProvider>().addToCart(p);
  }

  // ignore: use_build_context_synchronously
  Future<void> _pay() async {
    final tp = context.read<TransactionProvider>();
    final total = tp.total;
  final paidCtrl = TextEditingController(text: total.toStringAsFixed(0));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          // Normalize current method for UI (strip channel suffix like ewallet:OVO)
          String methodBase = tp.paymentMethod == 'cash' ? 'cash' : 'non_tunai';

          void setAmount(num v) {
            paidCtrl.text = v.toStringAsFixed(0);
            paidCtrl.selection = TextSelection.fromPosition(TextPosition(offset: paidCtrl.text.length));
            setState(() {});
          }

          return AlertDialog(
            title: const Text('Pembayaran'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Metode', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tunai'),
                        selected: methodBase == 'cash',
                        onSelected: (_) {
                          methodBase = 'cash';
                          tp.setPaymentMethod('cash');
                          tp.setPaymentChannel(null);
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Non-tunai'),
                        selected: methodBase != 'cash',
                        onSelected: (_) {
                          methodBase = 'non_tunai';
                          tp.setPaymentMethod('non_tunai');
                          tp.setPaymentChannel(null);
                          // auto fill exact total for non-tunai
                          setAmount(total);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    enabled: methodBase == 'cash',
                    decoration: const InputDecoration(labelText: 'Dibayar (Rp) — otomatis Pas untuk non-tunai'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => setAmount(total),
                        child: const Text('Pas (Exact)'),
                      ),
                      OutlinedButton(
                        onPressed: methodBase == 'cash' ? () => setAmount(10000) : null,
                        child: const Text('10.000'),
                      ),
                      OutlinedButton(
                        onPressed: methodBase == 'cash' ? () => setAmount(20000) : null,
                        child: const Text('20.000'),
                      ),
                      OutlinedButton(
                        onPressed: methodBase == 'cash' ? () => setAmount(50000) : null,
                        child: const Text('50.000'),
                      ),
                      OutlinedButton(
                        onPressed: methodBase == 'cash' ? () => setAmount(100000) : null,
                        child: const Text('100.000'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bayar')),
            ],
          );
        });
      },
    );

    if (ok == true) {
  final paid = tp.paymentMethod.split(':').first == 'cash' ? (double.tryParse(paidCtrl.text.trim()) ?? total) : total;
      // determine staff name: use explicit logged-in staff from Settings; if not set, use '-'
      String staffName = '-';
      try {
        final sp = context.read<SettingsProvider>();
        final loggedId = sp.loggedInStaffId;
        if (loggedId != null) {
          final spStaff = context.read<StaffProvider>();
          Staff? matched;
          try {
            matched = spStaff.staffs.firstWhere((s) => s.id == loggedId);
          } catch (_) {
            matched = null;
          }
          if (matched != null) staffName = matched.name;
        }
      } catch (_) {
        // if providers not available, keep '-'
      }
      final result = await tp.processTransaction(paid: paid, staffName: staffName);
      if (!mounted) return;
      if (result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaksi #${result.transactionNumber} berhasil')),
          );
        });
        // Cetak otomatis bila diaktifkan di Pengaturan (hanya desktop)
        final sp = context.read<SettingsProvider>();
        if (sp.btPrinterId?.isNotEmpty == true) {
          // Cetak langsung via Bluetooth Classic (tanpa dialog)
          final messenger = ScaffoldMessenger.of(context);
          try {
            final ok = await BluetoothClassicPrinter().printTransaction(
              mac: sp.btPrinterId!,
              trx: result,
              storeName: sp.storeName,
              storeAddress: sp.storeAddress,
              storePhone: sp.storePhone,
              paperSize: sp.paperSize,
              charWidth: sp.receiptCharWidth,
              receiptFooter: sp.receiptFooter,
            );
            if (!ok) {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Gagal cetak via Bluetooth')),
                );
              });
            }
          } catch (e) {
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('Gagal cetak Bluetooth: $e')),
              );
            });
          }
        }
      } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tp.errorMessage ?? 'Gagal memproses transaksi')),
            );
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final tp = context.watch<TransactionProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    Widget searchBar = Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: pp.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    pp.searchProducts('');
                  },
                )
              : null,
        ),
        onChanged: pp.searchProducts,
      ),
    );

    Widget categoryFilterWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Builder(builder: (context) {
        final cats = pp.categories;
        if (cats.length > 8) {
          // Use dropdown for long lists
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Kategori'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: pp.categoryFilter,
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua'),
                  ),
                  ...cats.map((c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c),
                      )),
                ],
                onChanged: (value) => pp.setCategoryFilter(value),
              ),
            ),
          );
        }
        // Otherwise chips for short lists
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: pp.categoryFilter == null || pp.categoryFilter!.isEmpty,
                  onSelected: (_) => pp.setCategoryFilter(null),
                ),
              ),
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: pp.categoryFilter == c,
                    onSelected: (_) => pp.setCategoryFilter(c),
                  ),
                ),
            ],
          ),
        );
      }),
    );

  Widget productsGrid = pp.isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(builder: (context, c) {
            int crossAxisCount = 2;
            final w = c.maxWidth;
            if (w >= 1200) {
              crossAxisCount = 5;
            } else if (w >= 1000) {
              crossAxisCount = 4;
            } else if (w >= 700) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: pp.products.length,
              itemBuilder: (context, index) {
                final p = pp.products[index];
                return InkWell(
                  onTap: () => _addToCart(p),
                  onLongPress: () async {
                    final qtyCtrl = TextEditingController(text: '1');
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Tambah Jumlah'),
                        content: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Batal')),
                          ElevatedButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Tambah')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                      if (q > 0) {
                        context.read<TransactionProvider>().addToCart(p, quantity: q);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.format(p.price),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Stok: ${p.stock}')
                      ],
                    ),
                  ),
                );
              },
            );
          });

    Widget cartList = ListView.separated(
      itemCount: tp.cartItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = tp.cartItems[index];
        final unit = CurrencyFormatter.format(item.product.price);
        final lineTotal = CurrencyFormatter.format(item.subtotal);
        return ListTile(
          title: Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('$unit x ${item.quantity} = $lineTotal'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => tp.decreaseQuantity(item.product.id!),
              ),
              Text('${item.quantity}'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => tp.addToCart(item.product),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => tp.removeFromCart(item.product.id!),
              ),
            ],
          ),
        );
      },
    );

    Widget summary = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Diskon (Rp)'),
                  onChanged: (v) => tp.setTransactionDiscount(double.tryParse(v.trim()) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _taxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pajak (Rp)'),
                  onChanged: (v) => tp.setTransactionTax(double.tryParse(v.trim()) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(CurrencyFormatter.format(tp.subtotal)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diskon:'),
              Text('- ${CurrencyFormatter.format(tp.transactionDiscount)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pajak:'),
              Text('+ ${CurrencyFormatter.format(tp.transactionTax)}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(CurrencyFormatter.format(tp.total), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: tp.cartItems.isEmpty ? null : () => tp.clearCart(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Kosongkan'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: tp.cartItems.isEmpty || tp.isProcessing ? null : _pay,
                icon: const Icon(Icons.payments),
                label: Text(tp.isProcessing ? 'Memproses…' : 'Bayar'),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Builder(builder: (context) {
              final sp = context.watch<SettingsProvider>();
              final staffProv = context.watch<StaffProvider>();
              String name = '-';
              final loggedId = sp.loggedInStaffId;
              if (loggedId != null) {
                try {
                  final matched = staffProv.staffs.firstWhere((s) => s.id == loggedId);
                  name = matched.name;
                } catch (_) {
                  // keep '-'
                }
              }
              return Text('Kasir: $name', style: const TextStyle(fontSize: 12, color: Colors.white70));
            }),
          ),
        ),
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
      body: isWide
          ? Row(
              children: [
                // Left: products
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      searchBar,
                      categoryFilterWidget,
                      Expanded(child: productsGrid),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right: cart and summary
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text('Keranjang (${tp.itemCount} item)'),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: tp.cartItems.isEmpty ? null : () => tp.clearCart(),
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Bersihkan'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(child: cartList),
                      summary,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                searchBar,
                categoryFilterWidget,
                SizedBox(
                  height: 200,
                  child: productsGrid,
                ),
                const Divider(height: 1),
                Expanded(child: cartList),
                summary,
              ],
            ),
    );
  }
}
