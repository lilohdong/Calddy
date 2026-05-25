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
