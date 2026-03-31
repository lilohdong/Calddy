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

  /// 현재 세션의 유저 정보 반환
  User? get currentUser;

  /// 인증 상태 변화를 감지하는 스트림
  Stream<AuthState> get onAuthStateChange;
}

/// Supabase와 GoogleSignIn을 이용한 인증 데이터 소스 구현체
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required SupabaseClient supabase,
    required GoogleSignIn googleSignIn,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn;

  @override
  Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('구글 로그인 중단');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw const AuthException('구글 인증 정보 획득 실패');
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
    return _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _supabase.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
