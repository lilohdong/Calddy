import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.userId,
    super.eventId,
    super.content,
    super.imageUrl,
    required super.visibility,
    required super.likesCount,
    required super.isLikedByMe,
    required super.feedDate,
    required super.createdAt,
  });

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    bool isLikedByMe = false,
  }) =>
      PostModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        eventId: json['event_id'] as String?,
        content: json['content'] as String?,
        imageUrl: json['image_url'] as String?,
        visibility: json['visibility'] == 'public'
            ? PostVisibility.public
            : PostVisibility.private,
        likesCount: (json['likes_count'] as int?) ?? 0,
        isLikedByMe: isLikedByMe,
        feedDate: DateTime.parse(json['feed_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
