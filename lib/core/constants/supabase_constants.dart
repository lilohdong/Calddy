import 'package:flutter/foundation.dart';

class SupabaseConstants {
  // ── Tables ────────────────────────────────────────────────────
  static const String profiles            = 'profiles';
  static const String events              = 'events';
  static const String habits              = 'habits';
  static const String habitLogs           = 'habit_logs';
  static const String ranges              = 'ranges';
  static const String drawings            = 'drawings';
  static const String posts               = 'posts';
  static const String postLikes           = 'post_likes';
  static const String comments            = 'comments';
  static const String appointments        = 'appointments';
  static const String appointmentInvites  = 'appointment_invites';
  static const String friendRequests      = 'friend_requests';
  static const String friends             = 'friends';
  static const String notifications       = 'notifications';
  static const String reports             = 'reports';
  static const String holidays            = 'holidays';

  // ── Storage Buckets ───────────────────────────────────────────
  static const String avatarsBucket   = 'avatars';
  static const String postsBucket     = 'posts';
  static const String drawingsBucket  = 'drawings';

  // ── 로컬/개발 환경 URL (env.json 또는 --dart-define) ──────────
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // 프로덕션 환경 URL (배포 시 CI --dart-define으로 주입)
  static const String _prodUrl = String.fromEnvironment('SUPABASE_PROD_URL');
  static const String _prodAnonKey = String.fromEnvironment('SUPABASE_PROD_ANON_KEY');

  // Android 에뮬레이터에서 127.0.0.1 → 10.0.2.2 자동 변환
  // (--dart-define 미설정 fallback 포함)
  static String get _localUrl {
    if (kIsWeb) return _envUrl.isNotEmpty ? _envUrl : 'http://127.0.0.1:54321';
    // --dart-define 미설정이면 로컬 기본값 사용
    final resolved =
        _envUrl.isNotEmpty ? _envUrl : 'http://127.0.0.1:54321';
    // Android 에뮬레이터는 호스트 PC를 10.0.2.2 로 접근해야 함
    if (defaultTargetPlatform == TargetPlatform.android &&
        resolved.contains('127.0.0.1')) {
      return resolved.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return resolved;
  }

  /// 빌드 모드에 따라 적절한 URL 반환.
  /// Release 빌드에서 SUPABASE_PROD_URL이 누락되면 즉시 에러를 던져
  /// 잘못된 빌드가 배포되는 것을 방지한다.
  static String get url {
    if (kReleaseMode) {
      if (_prodUrl.isEmpty) {
        throw StateError(
          '[Calddy] SUPABASE_PROD_URL이 설정되지 않았습니다.\n'
          'CI/CD 환경변수 또는 --dart-define에 SUPABASE_PROD_URL을 추가하세요.',
        );
      }
      return _prodUrl;
    }
    return _localUrl;
  }

  /// 빌드 모드에 따라 적절한 Anon Key 반환.
  /// Release 빌드에서 SUPABASE_PROD_ANON_KEY가 누락되면 즉시 에러를 던진다.
  static String get anonKey {
    if (kReleaseMode) {
      if (_prodAnonKey.isEmpty) {
        throw StateError(
          '[Calddy] SUPABASE_PROD_ANON_KEY가 설정되지 않았습니다.\n'
          'CI/CD 환경변수 또는 --dart-define에 SUPABASE_PROD_ANON_KEY를 추가하세요.',
        );
      }
      return _prodAnonKey;
    }
    return _envAnonKey;
  }
}
