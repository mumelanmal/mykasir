import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff.dart';
import '../../providers/staff_provider.dart';

class StaffFormScreen extends StatefulWidget {
  final Staff? staff;
  const StaffFormScreen({super.key, this.staff});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _role = 'cashier';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    if (s != null) {
      _nameCtrl.text = s.name;
      _phoneCtrl.text = s.phone ?? '';
      _emailCtrl.text = s.email ?? '';
      _addressCtrl.text = s.address ?? '';
      _pinCtrl.text = s.pin ?? '';
      _role = s.role;
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sp = context.read<StaffProvider>();
    final data = Staff(
      id: widget.staff?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      role: _role,
      pin: _pinCtrl.text.trim().isEmpty ? null : _pinCtrl.text.trim(),
      isActive: _isActive,
    );
    final ok = widget.staff == null ? await sp.addStaff(data) : await sp.updateStaff(data);
  if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sp.errorMessage ?? 'Gagal menyimpan data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Ubah Staff' : 'Tambah Staff')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'cashier'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: 'PIN (opsional)'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
