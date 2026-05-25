import '../../domain/entities/searched_user_entity.dart';

class SearchedUserModel extends SearchedUserEntity {
  const SearchedUserModel({
    required super.id,
    required super.nickname,
    super.avatarUrl,
    super.bio,
    required super.relationStatus,
    super.pendingRequestId,
  });

  factory SearchedUserModel.fromJson(
    Map<String, dynamic> json, {
    required FriendRelationStatus relationStatus,
    String? pendingRequestId,
  }) {
    return SearchedUserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      relationStatus: relationStatus,
      pendingRequestId: pendingRequestId,
    );
  }
}
