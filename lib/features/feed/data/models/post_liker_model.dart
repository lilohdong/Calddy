import '../../domain/entities/post_liker_entity.dart';

class PostLikerModel extends PostLikerEntity {
  const PostLikerModel({
    required super.userId,
    required super.nickname,
    super.avatarUrl,
    required super.isFriend,
  });

  factory PostLikerModel.fromJson(
    Map<String, dynamic> json, {
    required bool isFriend,
  }) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return PostLikerModel(
      userId: json['user_id'] as String,
      nickname: profile['nickname'] as String? ?? '',
      avatarUrl: profile['avatar_url'] as String?,
      isFriend: isFriend,
    );
  }
}
