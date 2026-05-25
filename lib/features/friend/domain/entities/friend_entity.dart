import 'package:calddy/features/auth/domain/entities/user_entity.dart';

/// 수락된 친구 관계 (friends 테이블 기반)
class FriendEntity {
  final String userId;
  final String friendId;
  final UserEntity friendProfile;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendEntity({
    required this.userId,
    required this.friendId,
    required this.friendProfile,
    required this.status,
    required this.createdAt,
  });
}

/// 받은 친구 요청 (friend_requests 테이블 기반, status = pending)
class FriendRequestEntity {
  final String id;
  final String requesterId;
  final UserEntity requesterProfile;
  final DateTime createdAt;

  const FriendRequestEntity({
    required this.id,
    required this.requesterId,
    required this.requesterProfile,
    required this.createdAt,
  });
}

enum FriendRequestStatus { pending, accepted, rejected }

enum FriendSortType { alphabetical, freeTimeOverlap }
