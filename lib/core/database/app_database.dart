import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();
  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'konecta.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        phone TEXT,
        username TEXT,
        avatar_path TEXT,
        bio TEXT,
        is_online INTEGER DEFAULT 0,
        last_seen INTEGER,
        is_blocked INTEGER DEFAULT 0,
        identity_public_key TEXT NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        avatar_path TEXT,
        last_message_id TEXT,
        last_message_preview TEXT,
        last_message_at INTEGER,
        unread_count INTEGER DEFAULT 0,
        is_muted INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        disappearing_seconds INTEGER,
        member_ids TEXT DEFAULT '',
        description TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        type INTEGER NOT NULL DEFAULT 0,
        encrypted_content TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        sent_at INTEGER NOT NULL,
        delivered_at INTEGER,
        read_at INTEGER,
        reply_to_id TEXT,
        media_path TEXT,
        media_mime_type TEXT,
        media_duration INTEGER,
        reaction_emoji TEXT,
        is_deleted INTEGER DEFAULT 0,
        is_starred INTEGER DEFAULT 0,
        disappears_at INTEGER,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');

    // Indices para rendimiento
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id, sent_at DESC)');
    await db.execute('CREATE INDEX idx_messages_starred ON messages(is_starred)');
    await db.execute('CREATE INDEX idx_chats_pinned ON chats(is_pinned DESC, last_message_at DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE chats ADD COLUMN last_message_preview TEXT');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
