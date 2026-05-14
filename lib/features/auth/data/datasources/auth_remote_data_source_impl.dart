import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

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
  Future<UserEntity?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) return null;
    final profile = await getUserProfile(user.id);
    return UserModel.fromSupabase(user, profile);
  }

  @override
  Future<UserEntity?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) return null;
    final profile = await getUserProfile(user.id);
    return UserModel.fromSupabase(user, profile);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _supabase.auth.signOut(),
      if (_googleSignIn != null) _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');
    // Edge Function을 통해 계정 삭제 처리 (서버 측 cascade 삭제)
    // user_id는 body에 포함하지 않음 — Edge Function이 Authorization 헤더의 JWT에서 uid를 추출함
    await _supabase.functions.invoke('delete-account');
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _supabase.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<void> completeOnboarding({
    required String nickname,
    required DateTime termsAgreedAt,
    required String termsVersion,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');
    await _supabase.from('profiles').update({
      'nickname': nickname,
      'is_onboarded': true,
      'terms_agreed_at': termsAgreedAt.toUtc().toIso8601String(),
      'terms_version': termsVersion,
    }).eq('id', userId);
  }

  @override
  Future<void> sendOtp(String email) async {
    // 회원가입 인증 메일 재발송. signUp() 호출 시 첫 발송은 Supabase가 자동 처리.
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // calddy://auth/reset-password → AndroidManifest.xml intent-filter와 일치
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
  UserEntity? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabase(user, null);
  }

  @override
  Stream<UserEntity?> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      // 최대 3회 시도. 모두 실패 시 에러 전파 → NetworkErrorPage로 라우팅.
      late Object lastError;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final profile = await getUserProfile(user.id);
          return UserModel.fromSupabase(user, profile);
        } catch (e) {
          lastError = e;
          if (attempt < 2) await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
      throw lastError;
    });
  }
}
