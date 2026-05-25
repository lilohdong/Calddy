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
