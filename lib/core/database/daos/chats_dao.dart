import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/chat_model.dart';

class ChatsDao {
  final _db = AppDatabase.instance;

  Future<void> upsert(ChatModel chat) async {
    final db = await _db.database;
    await db.insert('chats', chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatModel>> getAll({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'chats',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'is_pinned DESC, last_message_at DESC NULLS LAST',
    );
    return rows.map(ChatModel.fromMap).toList();
  }

  Future<ChatModel?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('chats', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ChatModel.fromMap(rows.first);
  }

  Future<void> updateLastMessage(
    String chatId, {
    required String messageId,
    required String preview,
    required DateTime sentAt,
  }) async {
    final db = await _db.database;
    await db.update(
      'chats',
      {
        'last_message_id': messageId,
        'last_message_preview': preview,
        'last_message_at': sentAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> incrementUnread(String chatId) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE chats SET unread_count = unread_count + 1 WHERE id = ?',
      [chatId],
    );
  }

  Future<void> clearUnread(String chatId) async {
    final db = await _db.database;
    await db.update('chats', {'unread_count': 0},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> togglePin(String chatId, bool pinned) async {
    final db = await _db.database;
    await db.update('chats', {'is_pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> toggleMute(String chatId, bool muted) async {
    final db = await _db.database;
    await db.update('chats', {'is_muted': muted ? 1 : 0},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> toggleArchive(String chatId, bool archived) async {
    final db = await _db.database;
    await db.update('chats', {'is_archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> delete(String chatId) async {
    final db = await _db.database;
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
  }
}

