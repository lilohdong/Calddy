import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// AuthRepository 인터페이스의 구체적인 구현체
/// Supabase AuthException을 도메인 AuthFailure로 변환하여 throw
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _remoteDataSource.signInWithGoogle();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<UserEntity?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserEntity?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _remoteDataSource.currentUser;
  }

  @override
  Future<void> completeOnboarding({
    required String nickname,
    required DateTime termsAgreedAt,
    required String termsVersion,
  }) async {
    // 1단계: 프로필 업데이트 — 실패 시 온보딩 전체를 실패로 처리
    try {
      await _remoteDataSource.completeOnboarding(
        nickname: nickname,
        termsAgreedAt: termsAgreedAt,
        termsVersion: termsVersion,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      // PostgreSQL unique constraint 위반 (에러 코드 23505) → 닉네임 중복
      if (e is PostgrestException && e.code == '23505') {
        throw const DuplicateNicknameFailure();
      }
      throw const UnknownAuthFailure();
    }

    // 2단계: 세션 갱신 — authStateChanges 스트림 재트리거용.
    // DB 업데이트는 이미 성공했으므로 갱신 실패는 온보딩 성공으로 간주하고 무시한다.
    // (스트림은 다음 세션 이벤트에서 자동으로 최신 프로필을 가져온다.)
    try {
      await _remoteDataSource.refreshSession();
    } on AuthException catch (_) {
      // 무시: 세션 만료 등의 이유로 갱신에 실패해도 온보딩 자체는 완료된 상태
    } catch (_) {
      // 무시: 동일한 이유
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await _remoteDataSource.sendOtp(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      await _remoteDataSource.verifyOtp(email: email, token: token);
    } on AuthException catch (e) {
      throw _mapOtpException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _remoteDataSource.updatePassword(newPassword);
    } on AuthException catch (e) {
      throw _mapUpdatePasswordException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _remoteDataSource.onAuthStateChange;

  // ── Private helpers ───────────────────────────────────────────

  /// 비밀번호 업데이트 실패를 도메인 Failure로 변환.
  AuthFailure _mapUpdatePasswordException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (_statusCode429(e)) return const TooManyRequestsFailure();
    if (msg.contains('weak password') ||
        msg.contains('password should be') ||
        msg.contains('password is too short')) {
      return const WeakPasswordFailure();
    }
    if (msg.contains('same password') ||
        msg.contains('different from the old password') ||
        msg.contains('should be different')) {
      return const SamePasswordFailure();
    }
    if (msg.contains('session_expired') || msg.contains('not authenticated')) {
      return const SessionExpiredAuthFailure();
    }
    return _mapAuthException(e);
  }

  /// OTP 검증 실패를 도메인 Failure로 변환.
  AuthFailure _mapOtpException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('expired') || msg.contains('otp_expired')) {
      return const OtpExpiredFailure();
    }
    if (msg.contains('invalid') || msg.contains('otp_disabled') ||
        msg.contains('token not found') || msg.contains('incorrect')) {
      return const InvalidOtpFailure();
    }
    if (_statusCode429(e)) return const TooManyRequestsFailure();
    return const UnknownAuthFailure();
  }

  bool _statusCode429(AuthException e) =>
      e.statusCode == '429' ||
      e.message.toLowerCase().contains('too many requests') ||
      e.message.toLowerCase().contains('rate limit');

  /// Supabase [AuthException]을 도메인 [AuthFailure]로 변환.
  /// statusCode를 1순위, message 패턴을 2순위로 사용하여
  /// SDK 버전업으로 메시지가 변경되어도 핵심 분류가 유지되도록 한다.
  AuthFailure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final statusCode = e.statusCode;

    // ── 앱 내부 커스텀 에러 코드 (statusCode 없음) ──────────────
    if (msg.contains('google_config_missing')) {
      return const GoogleConfigMissingFailure();
    }
    if (msg.contains('google_sign_in_cancelled')) {
      return const GoogleSignInCancelledFailure();
    }
    if (msg.contains('google_token_fetch_failed')) {
      return const NetworkFailure();
    }
    if (msg.contains('session_expired')) {
      return const SessionExpiredAuthFailure();
    }

    // ── HTTP 상태 코드 기반 분류 (1순위) ────────────────────────
    if (statusCode == '429' || msg.contains('too many requests') || msg.contains('rate limit')) {
      return const TooManyRequestsFailure();
    }
    if (statusCode == '422') {
      if (msg.contains('user already registered') ||
          msg.contains('email already') ||
          msg.contains('already been registered')) {
        return const EmailAlreadyInUseFailure();
      }
    }
    if (statusCode == '400') {
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          msg.contains('wrong password')) {
        return const InvalidCredentialsFailure();
      }
      if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
        return const EmailNotConfirmedFailure();
      }
    }

    // ── 메시지 패턴 기반 분류 (2순위 fallback) ──────────────────
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password')) {
      return const InvalidCredentialsFailure();
    }
    if (msg.contains('user already registered') ||
        msg.contains('email already') ||
        msg.contains('already been registered')) {
      return const EmailAlreadyInUseFailure();
    }
    if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
      return const EmailNotConfirmedFailure();
    }
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return const NetworkFailure();
    }

    return const UnknownAuthFailure();
  }
}
