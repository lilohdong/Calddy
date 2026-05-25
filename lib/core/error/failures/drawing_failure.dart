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
