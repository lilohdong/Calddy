enum PostVisibility { public, private }

class PostEntity {
  final String id;
  final String userId;
  final String? eventId;
  final String? content;
  final String? imageUrl;
  final PostVisibility visibility;
  final int likesCount;
  final bool isLikedByMe;
  final DateTime feedDate;
  final DateTime createdAt;

  const PostEntity({
    required this.id,
    required this.userId,
    this.eventId,
    this.content,
    this.imageUrl,
    required this.visibility,
    required this.likesCount,
    required this.isLikedByMe,
    required this.feedDate,
    required this.createdAt,
  });
}
