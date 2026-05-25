import 'package:calddy/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/friend_entity.dart';

/// friends 테이블 + profiles JOIN 결과를 파싱하는 모델
class FriendModel extends FriendEntity {
  const FriendModel({
    required super.userId,
    required super.friendId,
    required super.friendProfile,
    required super.status,
    required super.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>? ?? {};
    return FriendModel(
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      friendProfile: UserEntity(
        id: p['id'] as String? ?? json['friend_id'] as String,
        email: '',
        nickname: p['nickname'] as String?,
        avatarUrl: p['avatar_url'] as String?,
        isOnboarded: true,
      ),
      status: FriendRequestStatus.accepted,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// friend_requests 테이블 + profiles(requester) JOIN 결과를 파싱하는 모델
class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.id,
    required super.requesterId,
    required super.requesterProfile,
    required super.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>? ?? {};
    return FriendRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterProfile: UserEntity(
        id: p['id'] as String? ?? json['requester_id'] as String,
        email: '',
        nickname: p['nickname'] as String?,
        avatarUrl: p['avatar_url'] as String?,
        isOnboarded: true,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
