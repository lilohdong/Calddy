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
