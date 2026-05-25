/// 앱 전반에서 사용하는 Failure 계층 구조
/// sealed class를 활용하여 exhaustive pattern matching 지원 (Dart 3)
sealed class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

/// 이메일/비밀번호 불일치
final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('이메일 또는 비밀번호가 올바르지 않습니다.');
}

/// 이메일 중복 가입
final class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super('이미 사용 중인 이메일 주소입니다.');
}

/// 이메일 인증 미완료
final class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure()
      : super('이메일 인증이 완료되지 않았습니다.\n메일함을 확인해주세요.');
}

/// 구글 로그인 사용자가 직접 취소
final class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure()
      : super('구글 로그인이 취소되었습니다.');
}

/// GOOGLE_WEB_CLIENT_ID 환경변수 미설정
final class GoogleConfigMissingFailure extends AuthFailure {
  const GoogleConfigMissingFailure()
      : super('구글 로그인 설정이 올바르지 않습니다.\n앱을 업데이트하거나 관리자에게 문의해주세요.');
}

/// 요청 횟수 초과
final class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
      : super('요청이 너무 많습니다. 잠시 후 다시 시도해주세요.');
}

/// 닉네임 중복
final class DuplicateNicknameFailure extends AuthFailure {
  const DuplicateNicknameFailure()
      : super('이미 사용 중인 닉네임입니다.\n다른 닉네임을 입력해주세요.');
}

/// 네트워크 오류
final class NetworkFailure extends AuthFailure {
  const NetworkFailure()
      : super('네트워크 연결을 확인하고 다시 시도해주세요.');
}

/// 비밀번호 형식 오류 (Value Object 검증 실패)
final class PasswordValidationFailure extends AuthFailure {
  const PasswordValidationFailure(super.message);
}

/// 이메일 형식 오류
final class EmailValidationFailure extends AuthFailure {
  const EmailValidationFailure()
      : super('올바른 이메일 형식을 입력해주세요.');
}

/// 닉네임 형식 오류 (Value Object 검증 실패)
final class NicknameValidationFailure extends AuthFailure {
  const NicknameValidationFailure(super.message);
}

/// OTP 코드 불일치 또는 형식 오류
final class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure() : super('인증번호가 올바르지 않습니다.');
}

/// OTP 코드 만료
final class OtpExpiredFailure extends AuthFailure {
  const OtpExpiredFailure() : super('인증번호가 만료되었습니다.\n다시 발송해주세요.');
}

/// 분류되지 않은 서버 오류
final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure() : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}

// ── Calendar Failures ──────────────────────────────────────────────────────

sealed class CalendarFailure implements Exception {
  final String message;
  const CalendarFailure(this.message);
}

/// 세션 만료 (로그인 없이 캘린더 접근)
final class CalendarSessionExpiredFailure extends CalendarFailure {
  const CalendarSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// DB 쿼리 오류 (RLS 위반 등 Supabase PostgrestException)
final class CalendarDatabaseFailure extends CalendarFailure {
  const CalendarDatabaseFailure(super.message);
}

/// 분류되지 않은 캘린더 오류
final class CalendarUnknownFailure extends CalendarFailure {
  const CalendarUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
}

// ── Appointment Failures ───────────────────────────────────────────────────

sealed class AppointmentFailure implements Exception {
  final String message;
  const AppointmentFailure(this.message);
}

/// 세션 만료
final class AppointmentSessionExpiredFailure extends AppointmentFailure {
  const AppointmentSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// 약속 또는 초대를 찾을 수 없음
final class AppointmentNotFoundFailure extends AppointmentFailure {
  const AppointmentNotFoundFailure()
      : super('약속을 찾을 수 없습니다.');
}

/// DB 오류 (RLS 위반 등)
final class AppointmentDatabaseFailure extends AppointmentFailure {
  const AppointmentDatabaseFailure(super.message);
}

/// 분류되지 않은 오류
final class AppointmentUnknownFailure extends AppointmentFailure {
  const AppointmentUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
}

// ── Drawing Failures ───────────────────────────────────────────────────────

sealed class DrawingFailure implements Exception {
  final String message;
  const DrawingFailure(this.message);
}

final class DrawingSessionExpiredFailure extends DrawingFailure {
  const DrawingSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

final class DrawingDatabaseFailure extends DrawingFailure {
  const DrawingDatabaseFailure(super.message);
}

final class DrawingUnknownFailure extends DrawingFailure {
  const DrawingUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
}
// ── Friend Failures ────────────────────────────────────────────────────────

sealed class FriendFailure implements Exception {
  final String message;
  const FriendFailure(this.message);
}

/// 이미 친구 요청을 보낸 상태 (UNIQUE 제약 위반)
final class FriendRequestAlreadySentFailure extends FriendFailure {
  const FriendRequestAlreadySentFailure()
      : super('이미 친구 요청을 보냈습니다.');
}

/// 이미 친구인 상태에서 요청 재시도
final class AlreadyFriendsFailure extends FriendFailure {
  const AlreadyFriendsFailure() : super('이미 친구 관계입니다.');
}

/// 친구 요청을 찾을 수 없음 (삭제됐거나 잘못된 ID)
final class FriendRequestNotFoundFailure extends FriendFailure {
  const FriendRequestNotFoundFailure() : super('친구 요청을 찾을 수 없습니다.');
}

/// 분류되지 않은 친구 기능 오류
final class UnknownFriendFailure extends FriendFailure {
  const UnknownFriendFailure()
      : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}

// ── Feed Failures ──────────────────────────────────────────────────────────

sealed class FeedFailure implements Exception {
  final String message;
  const FeedFailure(this.message);
}

/// 세션 만료
final class FeedSessionExpiredFailure extends FeedFailure {
  const FeedSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// 게시글 없음 (잘못된 ID 또는 삭제됨)
final class FeedPostNotFoundFailure extends FeedFailure {
  const FeedPostNotFoundFailure() : super('게시글을 찾을 수 없습니다.');
}

/// 내용·이미지 둘 다 없음 (CHECK 제약 위반)
final class FeedContentRequiredFailure extends FeedFailure {
  const FeedContentRequiredFailure()
      : super('내용 또는 이미지 중 하나는 필요합니다.');
}

/// DB 오류 (RLS 위반 등)
final class FeedDatabaseFailure extends FeedFailure {
  const FeedDatabaseFailure(super.message);
}

/// 분류되지 않은 오류
final class FeedUnknownFailure extends FeedFailure {
  const FeedUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}
