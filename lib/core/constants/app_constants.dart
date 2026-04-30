class AppConstants {
  // 앱 기본 정보
  static const String appName = 'Calddy';

  // 닉네임 규칙
  static const int nicknameMinLength = 2;
  static const int nicknameMaxLength = 20;

  // 비밀번호 규칙
  static const int passwordMinLength = 8;

  // 피드 페이지네이션
  static const int feedPageSize = 20;

  // 재시도 횟수
  static const int maxRetryCount = 3;

  // 딥링크 스킴
  static const String deepLinkScheme = 'calddy';
  static const String passwordResetPath = 'auth/reset-password';
}
