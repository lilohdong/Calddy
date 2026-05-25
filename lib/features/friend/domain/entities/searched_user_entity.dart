/// 닉네임 검색 결과 엔티티
class SearchedUserEntity {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final FriendRelationStatus relationStatus;
  final String? pendingRequestId; // 수락/거절 시 필요한 friend_requests.id

  const SearchedUserEntity({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    required this.relationStatus,
    this.pendingRequestId,
  });
}

enum FriendRelationStatus {
  none,            // 친구 아님, 요청 없음
  requestSent,     // 내가 요청 보냄 (대기 중)
  requestReceived, // 상대가 나에게 요청 보냄
  friend,          // 이미 친구
}
