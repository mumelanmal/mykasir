import '../models/staff.dart';
import 'database_service.dart';

/// Service untuk operasi CRUD Staff
class StaffService {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Staff>> getAll({String? query}) async {
    final db = await _dbService.database;
    List<Map<String, Object?>> rows;
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      rows = await db.query(
        'staff',
        where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'created_at DESC',
      );
    } else {
      rows = await db.query('staff', orderBy: 'created_at DESC');
    }
    return rows.map((e) => Staff.fromMap(e)).toList();
  }

  Future<Staff?> getById(int id) async {
    final db = await _dbService.database;
    final rows = await db.query('staff', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Staff.fromMap(rows.first);
  }

  Future<int> insert(Staff staff) async {
    final db = await _dbService.database;
    return db.insert('staff', staff.toMap());
  }

  Future<int> update(Staff staff) async {
    if (staff.id == null) return 0;
    final db = await _dbService.database;
    return db.update('staff', staff.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [staff.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbService.database;
    return db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }
}
