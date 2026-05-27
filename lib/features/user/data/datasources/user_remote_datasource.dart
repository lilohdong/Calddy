import '../models/profile_model.dart';

abstract class UserRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateNickname(String nickname);
  Future<void> updateBirthDate(DateTime birthDate);

  /// 로컬 파일 경로를 받아 Storage에 업로드하고 공개 URL을 반환한다.
  /// profiles 테이블의 avatar_url도 함께 업데이트한다.
  Future<String?> updateAvatar(String filePath);

  Future<void> setPushNotification({required bool enabled, String? fcmToken});

  /// delete-account Edge Function을 호출하여 계정 탈퇴를 처리한다.
  Future<void> withdraw();
}
