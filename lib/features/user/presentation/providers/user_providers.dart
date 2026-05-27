import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/get_profile_use_case.dart';
import '../../domain/usecases/set_push_notification_use_case.dart';
import '../../domain/usecases/update_avatar_use_case.dart';
import '../../domain/usecases/update_birth_date_use_case.dart';
import '../../domain/usecases/update_nickname_use_case.dart';
import '../../domain/usecases/withdraw_use_case.dart';

// ── DataSource ────────────────────────────────────────────────────────────────

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
  );
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(userRepositoryProvider));
});

final updateNicknameUseCaseProvider = Provider<UpdateNicknameUseCase>((ref) {
  return UpdateNicknameUseCase(ref.watch(userRepositoryProvider));
});

final updateBirthDateUseCaseProvider = Provider<UpdateBirthDateUseCase>((ref) {
  return UpdateBirthDateUseCase(ref.watch(userRepositoryProvider));
});

final updateAvatarUseCaseProvider = Provider<UpdateAvatarUseCase>((ref) {
  return UpdateAvatarUseCase(ref.watch(userRepositoryProvider));
});

final setPushNotificationUseCaseProvider =
    Provider<SetPushNotificationUseCase>((ref) {
  return SetPushNotificationUseCase(ref.watch(userRepositoryProvider));
});

final withdrawUseCaseProvider = Provider<WithdrawUseCase>((ref) {
  return WithdrawUseCase(ref.watch(userRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

/// 현재 로그인 사용자의 프로필을 조회한다.
/// 세션이 없으면 null을 반환한다.
final currentUserProfileProvider =
    FutureProvider.autoDispose<ProfileEntity?>((ref) async {
  final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
  if (uid == null) return null;
  return ref
      .read(getProfileUseCaseProvider)
      .call(GetProfileParams(userId: uid));
});
