import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/call_record_model.dart';

class CallsDao {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<CallRecord>> getAll({int limit = 100}) async {
    final db = await _db;
    final rows = await db.query(
      'calls',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  Future<void> insert(CallRecord record) async {
    final db = await _db;
    await db.insert('calls', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOutcome(
      String id, CallOutcome outcome, int durationSeconds) async {
    final db = await _db;
    await db.update(
      'calls',
      {'outcome': outcome.index, 'duration_seconds': durationSeconds},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('calls', where: 'id = ?', whereArgs: [id]);
  }
}
