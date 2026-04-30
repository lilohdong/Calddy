import '../entities/profile_entity.dart';

abstract class UserRepository {
  Future<ProfileEntity> getProfile(String userId);
  Future<void> updateNickname(String nickname);
  Future<void> updateBirthDate(DateTime birthDate);
  Future<String?> updateAvatar(String filePath);
  Future<void> setPushNotification({required bool enabled, String? fcmToken});
  Future<void> withdraw();
}
