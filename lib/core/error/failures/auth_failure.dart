sealed class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('이메일 또는 비밀번호가 올바르지 않습니다.');
}

final class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super('이미 사용 중인 이메일 주소입니다.');
}

final class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure()
      : super('이메일 인증이 완료되지 않았습니다.\n메일함을 확인해주세요.');
}

final class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure()
      : super('구글 로그인이 취소되었습니다.');
}

final class GoogleConfigMissingFailure extends AuthFailure {
  const GoogleConfigMissingFailure()
      : super('구글 로그인 설정이 올바르지 않습니다.\n앱을 업데이트하거나 관리자에게 문의해주세요.');
}

final class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
      : super('요청이 너무 많습니다. 잠시 후 다시 시도해주세요.');
}

final class DuplicateNicknameFailure extends AuthFailure {
  const DuplicateNicknameFailure()
      : super('이미 사용 중인 닉네임입니다.\n다른 닉네임을 입력해주세요.');
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure()
      : super('네트워크 연결을 확인하고 다시 시도해주세요.');
}

final class PasswordValidationFailure extends AuthFailure {
  const PasswordValidationFailure(super.message);
}

final class EmailValidationFailure extends AuthFailure {
  const EmailValidationFailure()
      : super('올바른 이메일 형식을 입력해주세요.');
}

final class NicknameValidationFailure extends AuthFailure {
  const NicknameValidationFailure(super.message);
}

final class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure() : super('인증번호가 올바르지 않습니다.');
}

final class OtpExpiredFailure extends AuthFailure {
  const OtpExpiredFailure() : super('인증번호가 만료됐습니다.\n다시 발송해주세요.');
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure() : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}
