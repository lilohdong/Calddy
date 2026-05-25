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
