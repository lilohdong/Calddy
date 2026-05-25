class CommentEntity {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });
}
