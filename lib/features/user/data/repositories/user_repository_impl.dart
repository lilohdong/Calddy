import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../datasources/user_remote_datasource_impl.dart' show NicknameOnCooldownException;
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl({required UserRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ProfileEntity> getProfile(String userId) async {
    try {
      return await _remoteDataSource.getProfile(userId);
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } on PostgrestException {
      throw const ProfileFetchFailure();
    } catch (_) {
      throw const UserUnknownFailure();
    }
  }

  @override
  Future<void> updateNickname(String nickname) async {
    try {
      await _remoteDataSource.updateNickname(nickname);
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } on NicknameOnCooldownException {
      throw const NicknameChangeCooldownFailure();
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const NicknameTakenFailure();
      throw const ProfileUpdateFailure();
    } catch (_) {
      throw const UserUnknownFailure();
    }
  }

  @override
  Future<void> updateBirthDate(DateTime birthDate) async {
    try {
      await _remoteDataSource.updateBirthDate(birthDate);
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } on PostgrestException {
      throw const ProfileUpdateFailure();
    } catch (_) {
      throw const UserUnknownFailure();
    }
  }

  @override
  Future<String?> updateAvatar(String filePath) async {
    try {
      return await _remoteDataSource.updateAvatar(filePath);
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } on StorageException {
      throw const AvatarUploadFailure();
    } on PostgrestException {
      throw const AvatarUploadFailure();
    } catch (_) {
      throw const UserUnknownFailure();
    }
  }

  @override
  Future<void> setPushNotification({
    required bool enabled,
    String? fcmToken,
  }) async {
    try {
      await _remoteDataSource.setPushNotification(
        enabled: enabled,
        fcmToken: fcmToken,
      );
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } on PostgrestException {
      throw const ProfileUpdateFailure();
    } catch (_) {
      throw const UserUnknownFailure();
    }
  }

  @override
  Future<void> withdraw() async {
    try {
      await _remoteDataSource.withdraw();
    } on AuthException {
      throw const UserSessionExpiredFailure();
    } catch (_) {
      throw const WithdrawFailure();
    }
  }
}
