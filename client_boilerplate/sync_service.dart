import 'package:dio/dio.dart';
import 'database_helper.dart';

class SyncService {
  final Dio _dio = Dio();
  final String _baseUrl;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SyncService({required String baseUrl}) : _baseUrl = baseUrl;

  // 1. Sync Push: 로컬에서 작성한 미동기화 메모들을 서버로 업로드 (백업)
  Future<bool> syncPush(String deviceId) async {
    try {
      final unsynced = await _dbHelper.getUnsyncedNotes();
      if (unsynced.isEmpty) return true;

      // API 스펙에 맞추어 데이터 포맷팅
      final payload = {
        'device_id': deviceId,
        'notes': unsynced.map((n) => {
          'date': n['date'],
          'gratitude': n['gratitude'],
          'verse_highlight': n['verse_highlight'],
          'application': n['application'],
          'prayer': n['prayer'],
          'sunday_ibs': n['sunday_ibs'],
          'action_completed': n['action_completed'] == 1,
          'sermon_notes': n['sermon_notes'],
          'updated_at': n['updated_at']
        }).toList()
      };

      final response = await _dio.post(
        '$_baseUrl/api/v1/qt/sync',
        data: payload,
      );

      if (response.statusCode == 200) {
        // 성공 시 로컬 SQLite에 동기화 완료 처리
        final dates = unsynced.map((n) => n['date'] as String).toList();
        await _dbHelper.markNotesAsSynced(dates);
        return true;
      }
      return false;
    } catch (e) {
      print("Sync Push 실패: $e");
      return false;
    }
  }

  // 2. Sync Pull: 서버의 모든 데이터를 긁어와 로컬 DB와 비교 병합 (복원)
  Future<bool> syncPull(String deviceId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/qt/sync',
        queryParameters: {'device_id': deviceId},
      );

      if (response.statusCode != 200) return false;

      final List<dynamic> serverNotes = response.data['notes'];
      final localDb = await _dbHelper.database;

      for (var remote in serverNotes) {
        final date = remote['date'];
        final remoteUpdatedAt = remote['updated_at'];

        // 로컬에 해당 날짜 기록이 있는지 선조회
        final localRecords = await localDb.query(
          'qt_notes',
          where: 'date = ?',
          whereArgs: [date],
        );

        bool shouldOverwrite = true;
        if (localRecords.isNotEmpty) {
          final localUpdatedAt = localRecords.first['updated_at'] as String;
          // 로컬 데이터의 수정 타임스탬프가 서버보다 최신인 경우 덮어쓰지 않음 (Last-Write-Wins)
          if (localUpdatedAt.compareTo(remoteUpdatedAt) >= 0) {
            shouldOverwrite = false;
          }
        }

        if (shouldOverwrite) {
          final mappedNote = {
            'date': date,
            'gratitude': remote['gratitude'],
            'verse_highlight': remote['verse_highlight'],
            'application': remote['application'],
            'prayer': remote['prayer'],
            'sunday_ibs': remote['sunday_ibs'],
            'action_completed': remote['action_completed'] == true ? 1 : 0,
            'sermon_notes': remote['sermon_notes'],
            'is_synced': 1, // 서버에서 받아왔으므로 동기화 완료 처리
            'updated_at': remoteUpdatedAt
          };

          await localDb.insert(
            'qt_notes',
            mappedNote,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      return true;
    } catch (e) {
      print("Sync Pull 실패: $e");
      return false;
    }
  }
}
