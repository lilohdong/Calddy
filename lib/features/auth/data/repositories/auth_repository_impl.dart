import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

/// AuthRepository 인터페이스의 구체적인 구현체
/// Supabase AuthException을 도메인 AuthFailure로 변환하여 throw
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final response = await _remoteDataSource.signInWithGoogle();
      final user = response.user;
      if (user == null) return null;
      return _buildAppUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return null;
      return _buildAppUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return null;
      return _buildAppUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _remoteDataSource.currentUser;
    if (user == null) return null;
    return _buildAppUser(user);
  }

  @override
  Future<void> completeOnboarding({
    required String userId,
    required String nickname,
  }) async {
    // 1단계: 프로필 업데이트 — 실패 시 온보딩 전체를 실패로 처리
    try {
      await _remoteDataSource.completeOnboarding(
        userId: userId,
        nickname: nickname,
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
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _remoteDataSource.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      try {
        return await _buildAppUser(user);
      } catch (_) {
        // profiles 조회 실패 시 profile 없이 기본값으로 AppUser 반환.
        // 스트림 에러 전파를 막아 SplashPage가 LoginPage로 fallback하는 것을 방지.
        return AppUserModel.fromSupabase(user, null);
      }
    });
  }

  // ── Private helpers ───────────────────────────────────────────

  Future<AppUser> _buildAppUser(User user) async {
    final profile = await _remoteDataSource.getUserProfile(user.id);
    return AppUserModel.fromSupabase(user, profile);
  }

  /// Supabase [AuthException]을 도메인 [AuthFailure]로 변환
  AuthFailure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('google_config_missing')) {
      return const GoogleConfigMissingFailure();
    }
    if (msg.contains('google_sign_in_cancelled')) {
      return const GoogleSignInCancelledFailure();
    }
    if (msg.contains('google_token_fetch_failed')) {
      return const NetworkFailure();
    }
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
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return const TooManyRequestsFailure();
    }
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return const NetworkFailure();
    }

    return const UnknownAuthFailure();
  }
}
