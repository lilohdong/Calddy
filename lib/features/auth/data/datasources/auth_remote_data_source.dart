import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 외부 인증 서비스(Supabase, Google)와 직접 통신하는 데이터 소스 인터페이스
abstract class AuthRemoteDataSource {
  /// 구글 로그인을 수행하고 Supabase 인증 결과를 반환
  Future<AuthResponse> signInWithGoogle();

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

  /// 닉네임 저장 및 온보딩 완료 처리
  Future<void> completeOnboarding({
    required String userId,
    required String nickname,
  });

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);

  /// 세션 갱신 (authStateChanges 재트리거용)
  Future<void> refreshSession();

  /// 현재 세션의 유저 정보 반환
  User? get currentUser;

  /// 인증 상태 변화를 감지하는 스트림
  Stream<AuthState> get onAuthStateChange;
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
  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw const AuthException('google_config_missing');
    }

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

    return _supabase.auth.signInWithIdToken(
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
  Future<void> sendPasswordResetEmail(String email) async {
    // calddy://auth/reset-password → AndroidManifest.xml intent-filter와 일치
    // Supabase Flutter SDK가 onAuthStateChange로 PASSWORD_RECOVERY 이벤트를 자동 처리
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'calddy://auth/reset-password',
    );
  }

  @override
  Future<void> completeOnboarding({
    required String userId,
    required String nickname,
  }) async {
    await _supabase.from('profiles').update({
      'nickname': nickname,
      'is_onboarded': true,
    }).eq('id', userId);
  }

  @override
  Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
