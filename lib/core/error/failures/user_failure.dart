sealed class UserFailure implements Exception {
  final String message;
  const UserFailure(this.message);
}

/// 프로필 조회 실패
final class ProfileFetchFailure extends UserFailure {
  const ProfileFetchFailure() : super('프로필 조회에 실패했습니다.');
}

/// 프로필 업데이트 실패
final class ProfileUpdateFailure extends UserFailure {
  const ProfileUpdateFailure() : super('프로필 업데이트에 실패했습니다.');
}

/// 닉네임 중복
final class NicknameTakenFailure extends UserFailure {
  const NicknameTakenFailure() : super('이미 사용 중인 닉네임입니다.');
}

/// 닉네임 변경 30일 쿨다운
final class NicknameChangeCooldownFailure extends UserFailure {
  const NicknameChangeCooldownFailure()
      : super('닉네임은 변경 후 30일이 지나야 다시 변경할 수 있습니다.');
}

/// 아바타 업로드 실패
final class AvatarUploadFailure extends UserFailure {
  const AvatarUploadFailure() : super('프로필 이미지 업로드에 실패했습니다.');
}

/// 회원 탈퇴 실패
final class WithdrawFailure extends UserFailure {
  const WithdrawFailure() : super('회원 탈퇴에 실패했습니다.');
}

/// 세션 만료
final class UserSessionExpiredFailure extends UserFailure {
  const UserSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// 분류되지 않은 오류
final class UserUnknownFailure extends UserFailure {
  const UserUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}
