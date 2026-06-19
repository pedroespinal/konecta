import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/chat_model.dart';

class ContactsDao {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<ContactModel>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'contacts',
      where: 'is_blocked = 0',
      orderBy: 'display_name ASC',
    );
    return rows.map(ContactModel.fromMap).toList();
  }

  Future<void> upsert(ContactModel contact) async {
    final db = await _db;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<ContactModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : ContactModel.fromMap(rows.first);
  }
}
