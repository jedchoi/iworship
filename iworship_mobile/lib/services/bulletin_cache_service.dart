import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class BulletinCacheService {
  static const String _bulletinListKey = 'cached_bulletin_list_v2';
  static final Dio _dio = Dio();

  static String _buildKey(String imgUrl) {
    String sanitized = imgUrl.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'bulletin_img_v2_$sanitized';
  }

  /// 로컬 저장소에 캐시된 주보 목록 가져오기 (0.01초 즉시 로딩)
  static Future<List<Map<String, dynamic>>> getLocalBulletinList() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_bulletinListKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(raw);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        print('로컬 주보 목록 파싱 에러: $e');
      }
    }
    return [];
  }

  /// 최신 주보 목록을 로컬 저장소에 백업 저장
  static Future<void> saveLocalBulletinList(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bulletinListKey, jsonEncode(list));
  }

  /// 주보 지면 이미지의 로컬 바이트 데이터 가져오기
  static Future<Uint8List?> getCachedImageBytes(String imgUrl) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _buildKey(imgUrl);
    String? b64 = prefs.getString(key);
    if (b64 != null && b64.isNotEmpty) {
      try {
        return base64Decode(b64);
      } catch (e) {
        print('로컬 이미지 디코딩 에러: $e');
      }
    }
    return null;
  }

  /// 서버에서 주보 지면 이미지를 다운로드 받아 로컬 저장소에 백업 캐시
  static Future<Uint8List?> downloadAndCacheImage(String fullUrl, String imgUrl) async {
    try {
      final response = await _dio.get<List<int>>(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        Uint8List bytes = Uint8List.fromList(response.data!);
        String b64 = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        String key = _buildKey(imgUrl);
        await prefs.setString(key, b64);
        return bytes;
      }
    } catch (e) {
      print('주보 이미지 백업 다운로드 실패 ($fullUrl): $e');
    }
    return null;
  }

  /// 캐시 전체 초기화 (새로고침 시 호출)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String k in keys) {
      if (k.startsWith('bulletin_img_') || k.startsWith('cached_bulletin_list')) {
        await prefs.remove(k);
      }
    }
  }
}
