class PostLikerEntity {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final bool isFriend;

  const PostLikerEntity({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.isFriend,
  });
}
