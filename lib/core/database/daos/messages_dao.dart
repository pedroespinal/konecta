import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/message_model.dart';

class MessagesDao {
  final _db = AppDatabase.instance;

  Future<void> insert(MessageModel msg) async {
    final db = await _db.database;
    await db.insert('messages', msg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageModel>> getForChat(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'messages',
      where: 'chat_id = ? AND is_deleted = 0',
      whereArgs: [chatId],
      orderBy: 'sent_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Future<void> updateStatus(
    String id,
    MessageStatus status, {
    DateTime? deliveredAt,
    DateTime? readAt,
  }) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {
        'status': status.index,
        if (deliveredAt != null)
          'delivered_at': deliveredAt.millisecondsSinceEpoch,
        if (readAt != null) 'read_at': readAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllReadInChat(String chatId) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'messages',
      {'status': MessageStatus.read.index, 'read_at': now},
      where: 'chat_id = ? AND status < ?',
      whereArgs: [chatId, MessageStatus.read.index],
    );
  }

  Future<void> softDelete(String id) async {
    final db = await _db.database;
    await db.update('messages', {'is_deleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMessage(String id, String newEncryptedContent) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {'encrypted_content': newEncryptedContent},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setReaction(String id, String? emoji) async {
    final db = await _db.database;
    await db.update('messages', {'reaction_emoji': emoji},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleStar(String id, bool starred) async {
    final db = await _db.database;
    await db.update('messages', {'is_starred': starred ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MessageModel>> getStarred() async {
    final db = await _db.database;
    final rows = await db.query(
      'messages',
      where: 'is_starred = 1 AND is_deleted = 0',
      orderBy: 'sent_at DESC',
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Future<List<MessageModel>> search(String chatId, String query) async {
    final db = await _db.database;
    // Busca en el contenido CIFRADO codificado — la busqueda real
    // se hara en la capa de repositorio sobre contenido ya descifrado en memoria
    final rows = await db.query(
      'messages',
      where: 'chat_id = ? AND is_deleted = 0',
      whereArgs: [chatId],
      orderBy: 'sent_at DESC',
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Future<int> deleteExpired() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.delete('messages',
        where: 'disappears_at IS NOT NULL AND disappears_at < ?',
        whereArgs: [now]);
  }
}

