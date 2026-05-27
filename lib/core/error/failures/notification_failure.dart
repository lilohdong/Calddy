sealed class NotificationFailure implements Exception {
  final String message;
  const NotificationFailure(this.message);
}

/// 알림 목록 조회 실패
final class NotificationFetchFailure extends NotificationFailure {
  const NotificationFetchFailure() : super('알림 목록을 불러오는 데 실패했습니다.');
}

/// 알림 삭제 실패
final class NotificationDeleteFailure extends NotificationFailure {
  const NotificationDeleteFailure() : super('알림 삭제에 실패했습니다.');
}

/// 알림 상태 업데이트 실패 (읽음 처리 등)
final class NotificationUpdateFailure extends NotificationFailure {
  const NotificationUpdateFailure() : super('알림 상태 업데이트에 실패했습니다.');
}

/// 세션 만료
final class NotificationSessionExpiredFailure extends NotificationFailure {
  const NotificationSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// DB 오류 (RLS 위반 등)
final class NotificationDatabaseFailure extends NotificationFailure {
  const NotificationDatabaseFailure(super.message);
}

/// 분류되지 않은 오류
final class NotificationUnknownFailure extends NotificationFailure {
  const NotificationUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}
