import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

/// 외부 인증 서비스(Supabase, Google)와 직접 통신하는 데이터 소스 인터페이스
abstract class AuthRemoteDataSource {
  /// 구글 로그인 수행.
  /// 웹: Supabase OAuth 리다이렉트, 모바일: google_sign_in idToken 흐름.
  Future<void> signInWithGoogle();

  /// 이메일 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  /// 이메일 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  /// 로그아웃 수행
  Future<void> signOut();

  /// profiles 테이블에서 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  /// 닉네임 저장 및 온보딩 완료 처리 (userId는 내부에서 currentUser로 확인)
  Future<void> completeOnboarding({required String nickname});

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);

  /// 세션 갱신 (authStateChanges 재트리거용)
  Future<void> refreshSession();

  /// 현재 세션의 유저 정보 반환
  User? get currentUser;

  /// 인증 상태 변화를 감지하는 스트림 (도메인 타입으로 변환하여 방출)
  Stream<AppUser?> get onAuthStateChange;
}

/// Supabase와 GoogleSignIn을 이용한 인증 데이터 소스 구현체
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  /// null이면 GOOGLE_WEB_CLIENT_ID가 미설정된 것.
  /// signInWithGoogle() 호출 시 AuthException('google_config_missing')을 던진다.
  final GoogleSignIn? _googleSignIn;

  AuthRemoteDataSourceImpl({
    required SupabaseClient supabase,
    required GoogleSignIn? googleSignIn,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn;

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Uri.base.scheme}://${Uri.base.host}/',
      );
      return;
    }

    // 모바일: google_sign_in → signInWithIdToken 흐름
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw const AuthException('google_config_missing');
    }

    // 이전 세션 캐시로 인해 signIn()이 응답하지 않는 경우를 방지
    await googleSignIn.signOut();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('google_sign_in_cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw const AuthException('google_token_fetch_failed');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _supabase.auth.signOut(),
      // 구글 로그인을 사용하지 않았거나 미설정인 경우 스킵
      if (_googleSignIn != null) _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _supabase.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<void> completeOnboarding({required String nickname}) async {
    // RLS가 현재 인증된 유저의 프로필만 업데이트할 수 있도록 보장하므로
    // currentUser.id로 대상을 특정한다.
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');
    await _supabase.from('profiles').update({
      'nickname': nickname,
      'is_onboarded': true,
    }).eq('id', userId);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // calddy://auth/reset-password → AndroidManifest.xml intent-filter와 일치
    // Supabase Flutter SDK가 onAuthStateChange로 PASSWORD_RECOVERY 이벤트를 자동 처리
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'calddy://auth/reset-password',
    );
  }

  @override
  Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AppUser?> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      // 최대 3회 시도 (초기 1회 + 재시도 2회). 모두 실패 시 에러를 전파하여
      // authStateProvider가 AsyncError 상태가 되도록 한다 → NetworkErrorPage로 라우팅.
      late Object lastError;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final profile = await getUserProfile(user.id);
          return AppUserModel.fromSupabase(user, profile);
        } catch (e) {
          lastError = e;
          if (attempt < 2) await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
      throw lastError;
    });
  }
}
