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

  /// 3. LWW 동기화 Push (로컬 작성노트 서버로 백업 전송)
  Future<bool> pushSyncNotes(String deviceId, List<UserNote> notes) async {
    if (notes.isEmpty) return true;
    try {
      final payload = {
        'device_id': deviceId.trim(),
        'notes': notes.map((n) {
          List<String> ibsList = [];
          if (n.sundayAnswer1.isNotEmpty) ibsList.add('1. ${n.sundayAnswer1}');
          if (n.sundayAnswer2.isNotEmpty) ibsList.add('2. ${n.sundayAnswer2}');
          if (n.sundayAnswer3.isNotEmpty) ibsList.add('3. ${n.sundayAnswer3}');

          return {
            'date': n.date,
            'gratitude': n.todayThanks,
            'verse_highlight': n.engravedWord,
            'application': n.todayApplication,
            'prayer': n.todayPrayer,
            'sunday_ibs': ibsList.join('\n'),
            'sermon_notes': n.sermonNote,
            'updated_at': n.updatedAt,

            'today_thanks': n.todayThanks,
            'engraved_word': n.engravedWord,
            'today_application': n.todayApplication,
            'today_prayer': n.todayPrayer,
            'sunday_answer1': n.sundayAnswer1,
            'sunday_answer2': n.sundayAnswer2,
            'sunday_answer3': n.sundayAnswer3,
            'sermon_note': n.sermonNote,
          };
        }).toList(),
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
        'device_id': deviceId.trim(),
      });
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is List) {
          rawList = response.data;
        } else if (response.data is Map && response.data['notes'] is List) {
          rawList = response.data['notes'];
        }

        return rawList.map((item) {
          Map<String, dynamic> map = Map<String, dynamic>.from(item);
          String thanks = map['today_thanks'] ?? map['gratitude'] ?? '';
          String engraved = map['engraved_word'] ?? map['verse_highlight'] ?? '';
          String app = map['today_application'] ?? map['application'] ?? '';
          String prayer = map['today_prayer'] ?? map['prayer'] ?? '';
          String sermon = map['sermon_note'] ?? map['sermon_notes'] ?? '';
          String ans1 = map['sunday_answer1'] ?? '';
          String ans2 = map['sunday_answer2'] ?? '';
          String ans3 = map['sunday_answer3'] ?? '';
          String ibs = map['sunday_ibs'] ?? '';

          if (ans1.isEmpty && ans2.isEmpty && ans3.isEmpty && ibs.isNotEmpty) {
            List<String> lines = ibs.split('\n');
            for (var line in lines) {
              if (line.startsWith('1. ')) ans1 = line.substring(3);
              else if (line.startsWith('2. ')) ans2 = line.substring(3);
              else if (line.startsWith('3. ')) ans3 = line.substring(3);
            }
            if (ans1.isEmpty && lines.isNotEmpty) ans1 = lines[0];
          }

          return UserNote(
            date: map['date'] ?? '',
            todayThanks: thanks,
            engravedWord: engraved,
            todayApplication: app,
            todayPrayer: prayer,
            sundayAnswer1: ans1,
            sundayAnswer2: ans2,
            sundayAnswer3: ans3,
            sermonNote: sermon,
            updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
          );
        }).toList();
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
