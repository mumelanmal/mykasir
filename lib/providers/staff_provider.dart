import 'package:flutter/foundation.dart';

import '../models/staff.dart';
import '../services/staff_service.dart';

class StaffProvider extends ChangeNotifier {
  final StaffService _service = StaffService();

  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;
  List<Staff> _staffs = [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  List<Staff> get staffs => _staffs;

  Future<void> loadStaffs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _staffs = await _service.getAll(query: _searchQuery);
    } catch (e) {
      _errorMessage = 'Gagal memuat data staff: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String q) {
    _searchQuery = q;
    loadStaffs();
  }

  Future<bool> addStaff(Staff staff) async {
    try {
      await _service.insert(staff);
      await loadStaffs();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah staff: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStaff(Staff staff) async {
    try {
      await _service.update(staff);
      await loadStaffs();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui staff: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStaff(int id) async {
    try {
      await _service.delete(id);
      _staffs.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus staff: $e';
      notifyListeners();
      return false;
    }
  }
}
