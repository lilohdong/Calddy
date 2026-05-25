sealed class ReportFailure implements Exception {
  final String message;
  const ReportFailure(this.message);
}

/// 세션 만료
final class ReportSessionExpiredFailure extends ReportFailure {
  const ReportSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// 이미 신고한 대상 (UNIQUE 제약 위반)
final class ReportDuplicateFailure extends ReportFailure {
  const ReportDuplicateFailure()
      : super('이미 신고한 대상입니다.');
}

/// 분류되지 않은 오류
final class ReportUnknownFailure extends ReportFailure {
  const ReportUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
}
