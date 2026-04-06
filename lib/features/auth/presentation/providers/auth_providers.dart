import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_in_with_email_use_case.dart';
import '../../domain/usecases/sign_up_with_email_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/complete_onboarding_use_case.dart';
import '../../domain/usecases/send_password_reset_email_use_case.dart';

/// 인증 데이터 소스 프로바이더
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

/// 인증 리포지토리 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

/// 인증 상태 스트림 프로바이더
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// 현재 사용자 정보 프로바이더
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ── UseCase 프로바이더 ──────────────────────────────────────────

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  return SignUpWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>((ref) {
  return CompleteOnboardingUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider = Provider<SendPasswordResetEmailUseCase>((ref) {
  return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
});
