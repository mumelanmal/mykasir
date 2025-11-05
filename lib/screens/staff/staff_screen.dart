import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff.dart';
import '../../providers/staff_provider.dart';
import 'staff_form_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaffs();
    });
  }

  Future<void> _refresh() async {
    await context.read<StaffProvider>().loadStaffs();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StaffProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
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
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama/email/telepon…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: sp.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          sp.search('');
                        },
                      )
                    : null,
              ),
              onChanged: sp.search,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: sp.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sp.errorMessage != null
                      ? ListView(children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(sp.errorMessage!),
                          )
                        ])
                      : ListView.separated(
                          itemCount: sp.staffs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final Staff s = sp.staffs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                              ),
                              title: Text(s.name),
                              subtitle: Text('${s.role} • ${s.isActive ? 'Aktif' : 'Nonaktif'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final updated = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => StaffFormScreen(staff: s),
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      if (updated == true) sp.loadStaffs();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: s.id == null
                                        ? null
                                        : () async {
                                            final ok = await sp.deleteStaff(s.id!);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(ok ? 'Staff dihapus' : 'Gagal menghapus staff')),
                                            );
                                          },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final updated = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => StaffFormScreen(staff: s),
                                  ),
                                );
                                if (!context.mounted) return;
                                if (updated == true) sp.loadStaffs();
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
            MaterialPageRoute(builder: (_) => const StaffFormScreen()),
          );
          if (!context.mounted) return;
          if (created == true) sp.loadStaffs();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

