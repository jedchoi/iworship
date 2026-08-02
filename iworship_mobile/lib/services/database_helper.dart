import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('iworship_local.db');
    return _database!;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) return null;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. 성경 묵상 본문 서버 캐시 테이블
    await db.execute('''
      CREATE TABLE daily_scriptures_cache (
        date TEXT PRIMARY KEY,
        title TEXT,
        passage TEXT,
        verses_json TEXT,
        bgm_commentary TEXT,
        weekly_pray_category TEXT,
        weekly_prayer TEXT,
        calligraphy_text TEXT,
        calligraphy_ref TEXT
      )
    ''');

    // 2. 사용자 작성 묵상 노트 및 설교 노트 테이블
    await db.execute('''
      CREATE TABLE user_notes (
        date TEXT PRIMARY KEY,
        today_thanks TEXT,
        engraved_word TEXT,
        today_application TEXT,
        today_prayer TEXT,
        sunday_answer1 TEXT,
        sunday_answer2 TEXT,
        sunday_answer3 TEXT,
        sermon_note TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // === UserNote CRUD ===
  Future<int> upsertUserNote(UserNote note) async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert(
      'user_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserNote?> getUserNote(String date) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;
    final maps = await db.query(
      'user_notes',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return UserNote.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserNote>> getUnsyncedNotes() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];
    final maps = await db.query(
      'user_notes',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => UserNote.fromMap(m)).toList();
  }

  Future<List<UserNote>> getAllUserNotes() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];
    final maps = await db.query('user_notes');
    return maps.map((m) => UserNote.fromMap(m)).toList();
  }

  Future<int> markAsSynced(String date) async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update(
      'user_notes',
      {'is_synced': 1},
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // === Scripture Cache CRUD ===
  Future<void> cacheScriptures(List<Map<String, dynamic>> scriptures) async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    final batch = db.batch();
    for (var s in scriptures) {
      batch.insert(
        'daily_scriptures_cache',
        s,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getCachedScripture(String date) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;
    final maps = await db.query(
      'daily_scriptures_cache',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
