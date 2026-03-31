import 'package:flutter/foundation.dart';

class SupabaseConstants {
  // env.json 또는 --dart-define을 통해 전달받은 URL
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  
  // env.json 또는 --dart-define을 통해 전달받은 Anon Key
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // 로컬 개발 환경용 URL 처리 (Android 에뮬레이터 대응)
  static String get _localUrl {
    if (kIsWeb) return _envUrl.isNotEmpty ? _envUrl : 'http://127.0.0.1:54321';
    
    // Android 에뮬레이터에서 127.0.0.1은 10.0.2.2로 자동 전환
    if (defaultTargetPlatform == TargetPlatform.android && _envUrl.contains('127.0.0.1')) {
      return _envUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return _envUrl.isNotEmpty ? _envUrl : 'http://127.0.0.1:54321';
  }

  // 배포 환경 (전시회용) - 배포 시에만 이 값을 직접 채워 넣거나, 배포용 env.json 사용
  static const String _prodUrl = 'YOUR_SUPABASE_CLOUD_URL';
  static const String _prodAnonKey = 'YOUR_SUPABASE_CLOUD_ANON_KEY';

  /// 현재 빌드 모드에 따라 적절한 URL 반환
  static String get url => kReleaseMode ? _prodUrl : _localUrl;

  /// 현재 빌드 모드에 따라 적절한 Anon Key 반환
  static String get anonKey => kReleaseMode ? _prodAnonKey : _envAnonKey;
}
