import 'package:dio/dio.dart';
import '../models/daily_scripture.dart';
import '../models/weekly_intro.dart';
import '../models/user_note.dart';

class ApiService {
  late Dio _dio;
  String baseUrl;

  ApiService({this.baseUrl = 'http://168.110.63.231:8000'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
  }

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  /// 1. 서버의 전체 성경 묵상 본문 데이터 내려받기 (Bulk Fetch)
  Future<List<DailyScripture>> fetchBulkScriptures() async {
    try {
      final response = await _dio.get('/api/v1/qt/bulk');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => DailyScripture.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Failed to fetch bulk scriptures: $e');
      return [];
    }
  }

  /// 2. 주간 모달창 구성 정보 조회
  Future<WeeklyIntroModel?> fetchWeeklyIntro(String startDate) async {
    try {
      final response = await _dio.get('/api/v1/qt/weekly-intro', queryParameters: {
        'start_date': startDate,
      });
      if (response.statusCode == 200) {
        return WeeklyIntroModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Failed to fetch weekly intro: $e');
      return null;
    }
  }

  /// 3. LWW 동기화 Push (로컬 미동기화 작성노트 서버로 전송)
  Future<bool> pushSyncNotes(String deviceId, List<UserNote> notes) async {
    if (notes.isEmpty) return true;
    try {
      final payload = {
        'device_id': deviceId,
        'notes': notes.map((n) => n.toMap()).toList(),
      };
      final response = await _dio.post('/api/v1/qt/sync', data: payload);
      return response.statusCode == 200;
    } catch (e) {
      print('Push sync failed: $e');
      return false;
    }
  }

  /// 4. LWW 동기화 Pull (서버의 백업 노트 복원)
  Future<List<UserNote>> pullSyncNotes(String deviceId) async {
    try {
      final response = await _dio.get('/api/v1/qt/sync', queryParameters: {
        'device_id': deviceId,
      });
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => UserNote.fromMap(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Pull sync failed: $e');
      return [];
    }
  }

  /// 5. 주보 목록 조회
  Future<List<Map<String, dynamic>>> fetchBulletins() async {
    try {
      final response = await _dio.get('/api/v1/church/bulletins');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print('Fetch bulletins failed: $e');
      return [];
    }
  }
}
