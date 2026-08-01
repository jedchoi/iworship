import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'iworship_local.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. 사용자 묵상 기록 테이블 생성 (평일 4개 항목 + 주일 IBS + 설교노트)
    await db.execute('''
      CREATE TABLE qt_notes (
        date TEXT PRIMARY KEY,
        gratitude TEXT,
        verse_highlight TEXT,
        application TEXT,
        prayer TEXT,
        sunday_ibs TEXT,
        action_completed INTEGER DEFAULT 0,
        sermon_notes TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 2. 구절별 인라인 메모 테이블 생성 (독서화면 인라인메모용)
    await db.execute('''
      CREATE TABLE verse_notes (
        date TEXT,
        verse_num INTEGER,
        note_text TEXT,
        updated_at TEXT,
        PRIMARY KEY (date, verse_num)
      )
    ''');
  }

  // QT 노트 저장/수정 (자동 로컬 저장용)
  Future<void> saveQtNote(Map<String, dynamic> note) async {
    final db = await database;
    note['is_synced'] = 0; // 수정 시 미동기화 상태로 갱신
    note['updated_at'] = DateTime.now().toUtc().toIso8601String();
    
    await db.insert(
      'qt_notes',
      note,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 동기화 완료 후 상태 일괄 업데이트
  Future<void> markNotesAsSynced(List<String> dates) async {
    final db = await database;
    await db.transaction((txn) async {
      for (String date in dates) {
        await txn.update(
          'qt_notes',
          {'is_synced': 1},
          where: 'date = ?',
          whereArgs: [date],
        );
      }
    });
  }

  // 동기화 필요 레코드 목록 조회 (Sync Push 대상)
  Future<List<Map<String, dynamic>>> getUnsyncedNotes() async {
    final db = await database;
    return await db.query(
      'qt_notes',
      where: 'is_synced = 0',
    );
  }
}
