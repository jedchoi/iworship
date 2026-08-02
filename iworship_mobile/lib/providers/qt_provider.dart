import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_scripture.dart';
import '../models/user_note.dart';
import '../models/weekly_intro.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class QtProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  double _fontSize = 17.0;
  bool _isLoading = false;
  String _deviceId = 'device_demo_001';

  DailyScripture? _currentScripture;
  UserNote? _currentUserNote;
  WeeklyIntroModel? _currentWeeklyIntro;
  List<DailyScripture> _bulkScripturesCache = [];

  String get selectedDate => _selectedDate;
  double get fontSize => _fontSize;
  bool get isLoading => _isLoading;
  DailyScripture? get currentScripture => _currentScripture;
  UserNote? get currentUserNote => _currentUserNote;
  WeeklyIntroModel? get currentWeeklyIntro => _currentWeeklyIntro;

  bool get isSunday {
    try {
      DateTime dt = DateTime.parse(_selectedDate);
      return dt.weekday == DateTime.sunday;
    } catch (_) {
      return false;
    }
  }

  // 주간 7일 가로 달력 스트립 날짜 리스트 (일요일 ~ 토요일)
  List<DateTime> get weeklyDates {
    try {
      DateTime dt = DateTime.parse(_selectedDate);
      DateTime sunday = dt.subtract(Duration(days: dt.weekday % 7));
      return List.generate(7, (i) => sunday.add(Duration(days: i)));
    } catch (_) {
      DateTime now = DateTime.now();
      DateTime sunday = now.subtract(Duration(days: now.weekday % 7));
      return List.generate(7, (i) => sunday.add(Duration(days: i)));
    }
  }

  // 주차 라벨 (예: 7월 5주차, 8월 1주차, 9월 1주차, 9월 2주차 - 수요일 기준 과반수 원칙)
  String get currentWeekLabel {
    try {
      DateTime dt = DateTime.parse(_selectedDate);
      DateTime sundayDt = dt.subtract(Duration(days: dt.weekday % 7));
      DateTime wednesdayDt = sundayDt.add(const Duration(days: 3));

      int ownerMonth = wednesdayDt.month;
      int ownerYear = wednesdayDt.year;

      DateTime firstDayOfMonth = DateTime(ownerYear, ownerMonth, 1);
      DateTime firstSun = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
      DateTime firstWed = firstSun.add(const Duration(days: 3));
      if (firstWed.month != ownerMonth) {
        firstWed = firstWed.add(const Duration(days: 7));
      }

      int weekNumber = (wednesdayDt.difference(firstWed).inDays ~/ 7) + 1;
      return '$ownerMonth월 $weekNumber주차';
    } catch (_) {
      return '주차 정보';
    }
  }

  String get deviceId => _deviceId;

  QtProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id') ?? 'IW-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    await prefs.setString('device_id', _deviceId);
    
    _fontSize = prefs.getDouble('font_size') ?? 17.0;

    String defaultServer;
    if (kIsWeb) {
      defaultServer = Uri.base.origin;
    } else {
      defaultServer = 'http://168.110.63.231:8000';
    }

    final savedServer = prefs.getString('server_url');
    String activeServer = (kIsWeb || savedServer == null || savedServer.isEmpty) ? defaultServer : savedServer;
    apiService.updateBaseUrl(activeServer);

    // 오프라인 방어를 위해 로컬 저장소 캐시 데이터 우선 로드
    await _loadLocalCachedScriptures();
    await loadDataForDate(_selectedDate);
  }

  // 1. SharedPreferences 로컬 저장소에서 캐시된 성경 본문 읽기
  Future<void> _loadLocalCachedScriptures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedJson = prefs.getString('bulk_scriptures_cache');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        List<dynamic> list = json.decode(cachedJson);
        _bulkScripturesCache = list.map((item) => DailyScripture.fromJson(item)).toList();
        _findCurrentScriptureForDate(_selectedDate);
      }
    } catch (e) {
      if (kDebugMode) print('로컬 캐시 성경 읽기 에러: $e');
    }
  }

  // 2. 서버에서 받은 최신 성경 본문을 SharedPreferences 로컬 저장소에 영구 저장
  Future<void> _saveLocalCachedScriptures(List<DailyScripture> scriptures) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> jsonList = scriptures.map((s) => s.toJson()).toList();
      await prefs.setString('bulk_scriptures_cache', json.encode(jsonList));
    } catch (e) {
      if (kDebugMode) print('로컬 캐시 성경 저장 에러: $e');
    }
  }

  void _findCurrentScriptureForDate(String dateStr) {
    _currentScripture = null;
    for (var s in _bulkScripturesCache) {
      if (s.date == dateStr) {
        _currentScripture = s;
        break;
      }
    }
  }

  void updateServerUrl(String url) async {
    apiService.updateBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    notifyListeners();
  }

  void updateDeviceId(String newId) async {
    String trimmed = newId.trim();
    if (trimmed.isEmpty) return;
    _deviceId = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', _deviceId);
    notifyListeners();
  }

  void setDate(String dateStr) {
    if (_selectedDate == dateStr) return;
    _selectedDate = dateStr;
    loadDataForDate(dateStr);
  }

  void previousWeek() {
    try {
      DateTime dt = DateTime.parse(_selectedDate);
      DateTime prev = dt.subtract(const Duration(days: 7));
      setDate(DateFormat('yyyy-MM-dd').format(prev));
    } catch (_) {}
  }

  void nextWeek() {
    try {
      DateTime dt = DateTime.parse(_selectedDate);
      DateTime next = dt.add(const Duration(days: 7));
      setDate(DateFormat('yyyy-MM-dd').format(next));
    } catch (_) {}
  }

  void setFontSize(double size) async {
    _fontSize = size.clamp(13.0, 26.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
  }

  // 오프라인 우선(Local-First) 데이터 로딩 및 서버 백그라운드 동기화
  Future<void> loadDataForDate(String dateStr) async {
    _isLoading = true;
    _currentScripture = null;
    _currentUserNote = null;
    notifyListeners();

    try {
      // Step 1: 로컬 SQLite/SharedPreferences에서 사용자 작성 노트 및 캐시 데이터 읽기
      if (kIsWeb) {
        _currentUserNote = await _getWebUserNote(dateStr);
      } else {
        _currentUserNote = await dbHelper.getUserNote(dateStr);
      }
      
      if (_bulkScripturesCache.isEmpty) {
        await _loadLocalCachedScriptures();
      } else {
        _findCurrentScriptureForDate(dateStr);
      }
    } catch (e) {
      if (kDebugMode) print('loadDataForDate 예외 처리: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Step 2: 백그라운드에서 서버와 통신하여 데이터 최신화
    _syncWithServerInBackground(dateStr);
  }

  Future<void> _syncWithServerInBackground(String dateStr) async {
    try {
      var serverScriptures = await apiService.fetchBulkScriptures();
      if (serverScriptures.isNotEmpty) {
        _bulkScripturesCache = serverScriptures;
        _saveLocalCachedScriptures(serverScriptures);
        _findCurrentScriptureForDate(_selectedDate);
        notifyListeners();
      }

      try {
        DateTime dt = DateTime.parse(dateStr);
        DateTime sundayDate = dt.subtract(Duration(days: dt.weekday % 7));
        String sundayStr = DateFormat('yyyy-MM-dd').format(sundayDate);
        var weeklyIntro = await apiService.fetchWeeklyIntro(sundayStr);
        if (weeklyIntro != null) {
          _currentWeeklyIntro = weeklyIntro;
          notifyListeners();
        }
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('서버 오프라인 대기 (로컬 캐시 사용 중): $e');
    }
  }

  // 구절 선택 시 Page 2의 '아로새길 말씀'으로 자동 추가하는 기능 (Feature 3-4)
  Future<void> appendEngravedWord(String verseText) async {
    String currentText = _currentUserNote?.engravedWord ?? '';
    String newText = currentText.isEmpty ? verseText : '$currentText\n$verseText';

    if (isSunday) {
      await saveUserNote(
        sundayAnswer1: _currentUserNote?.sundayAnswer1 ?? '',
        sundayAnswer2: _currentUserNote?.sundayAnswer2 ?? '',
        sundayAnswer3: _currentUserNote?.sundayAnswer3 ?? '',
        sermonNote: _currentUserNote?.sermonNote ?? '',
      );
    } else {
      await saveUserNote(
        todayThanks: _currentUserNote?.todayThanks ?? '',
        engravedWord: newText,
        todayApplication: _currentUserNote?.todayApplication ?? '',
        todayPrayer: _currentUserNote?.todayPrayer ?? '',
      );
    }
  }

  // 웹 전용 SharedPreferences 헬퍼
  Future<UserNote?> _getWebUserNote(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString('user_note_$dateStr');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return UserNote.fromMap(json.decode(jsonStr));
      }
    } catch (e) {
      if (kDebugMode) print('웹 노트 읽기 예외: $e');
    }
    return null;
  }

  Future<void> _saveWebUserNote(UserNote note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_note_${note.date}', json.encode(note.toMap()));
    } catch (e) {
      if (kDebugMode) print('웹 노트 저장 예외: $e');
    }
  }

  // === 사용자 묵상 노트 단일 저장 (앱: SQLite 100% / 웹: SharedPreferences 100%) ===
  Future<void> saveUserNote({
    String? todayThanks,
    String? engravedWord,
    String? todayApplication,
    String? todayPrayer,
    String? sundayAnswer1,
    String? sundayAnswer2,
    String? sundayAnswer3,
    String? sermonNote,
  }) async {
    UserNote current = _currentUserNote ?? UserNote(
      date: _selectedDate,
      updatedAt: DateTime.now().toIso8601String(),
    );

    UserNote newNote = UserNote(
      date: _selectedDate,
      todayThanks: todayThanks ?? current.todayThanks,
      engravedWord: engravedWord ?? current.engravedWord,
      todayApplication: todayApplication ?? current.todayApplication,
      todayPrayer: todayPrayer ?? current.todayPrayer,
      sundayAnswer1: sundayAnswer1 ?? current.sundayAnswer1,
      sundayAnswer2: sundayAnswer2 ?? current.sundayAnswer2,
      sundayAnswer3: sundayAnswer3 ?? current.sundayAnswer3,
      sermonNote: sermonNote ?? current.sermonNote,
      updatedAt: DateTime.now().toIso8601String(),
      isSynced: 0,
    );

    // 플랫폼별 단일 전담 저장소 사용 (용량 중복 없음)
    if (kIsWeb) {
      await _saveWebUserNote(newNote);
    } else {
      await dbHelper.upsertUserNote(newNote);
    }
    _currentUserNote = newNote;
    notifyListeners();

    // 서버로 백그라운드 동기화 (LWW Push)
    triggerSyncPush();
  }

  // 실시간 타이핑 중 한글 조합 분리 방지용 무소음(Silent) 저장 헬퍼 (notifyListeners 미호출)
  Future<void> saveUserNoteSilently({
    String? todayThanks,
    String? engravedWord,
    String? todayApplication,
    String? todayPrayer,
    String? sundayAnswer1,
    String? sundayAnswer2,
    String? sundayAnswer3,
    String? sermonNote,
  }) async {
    UserNote current = _currentUserNote ?? UserNote(
      date: _selectedDate,
      updatedAt: DateTime.now().toIso8601String(),
    );

    UserNote newNote = UserNote(
      date: _selectedDate,
      todayThanks: todayThanks ?? current.todayThanks,
      engravedWord: engravedWord ?? current.engravedWord,
      todayApplication: todayApplication ?? current.todayApplication,
      todayPrayer: todayPrayer ?? current.todayPrayer,
      sundayAnswer1: sundayAnswer1 ?? current.sundayAnswer1,
      sundayAnswer2: sundayAnswer2 ?? current.sundayAnswer2,
      sundayAnswer3: sundayAnswer3 ?? current.sundayAnswer3,
      sermonNote: sermonNote ?? current.sermonNote,
      updatedAt: DateTime.now().toIso8601String(),
      isSynced: 0,
    );

    _currentUserNote = newNote;

    if (kIsWeb) {
      await _saveWebUserNote(newNote);
    } else {
      await dbHelper.upsertUserNote(newNote);
    }
  }

  Future<List<UserNote>> getAllUserNotesForBackup() async {
    List<UserNote> allNotes = [];
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('user_note_')) {
          String? jsonStr = prefs.getString(key);
          if (jsonStr != null && jsonStr.isNotEmpty) {
            try {
              allNotes.add(UserNote.fromMap(json.decode(jsonStr)));
            } catch (_) {}
          }
        }
      }
    } else {
      allNotes = await dbHelper.getAllUserNotes();
    }
    return allNotes;
  }

  Future<bool> triggerSyncPush() async {
    List<UserNote> notesToBackup = await getAllUserNotesForBackup();
    if (notesToBackup.isNotEmpty) {
      bool success = await apiService.pushSyncNotes(_deviceId, notesToBackup);
      if (success && !kIsWeb) {
        for (var note in notesToBackup) {
          await dbHelper.markAsSynced(note.date);
        }
      }
      return success;
    }
    return true;
  }

  Future<int> restoreUserNotesFromBackup() async {
    String activeId = _deviceId;
    List<UserNote> restored = await apiService.pullSyncNotes(activeId);
    if (restored.isNotEmpty) {
      for (var note in restored) {
        if (kIsWeb) {
          await _saveWebUserNote(note);
        } else {
          await dbHelper.upsertUserNote(note);
        }
      }
      await loadDataForDate(_selectedDate);
    }
    return restored.length;
  }
}
