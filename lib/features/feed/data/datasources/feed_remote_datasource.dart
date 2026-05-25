import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';

abstract class FeedRemoteDataSource {
  Future<List<PostEntity>> getFeedByDate(DateTime date);

  Future<void> createPost({
    String? content,
    List<int>? imageBytes,
    String? imageExtension,
    required String visibility,
    required String feedDate,
    String? eventId,
  });

  Future<void> updatePost({
    required String postId,
    String? content,
    required String visibility,
  });

  Future<void> deletePost(String postId);

  // ── P2 ────────────────────────────────────────────────────────────────────

  Future<void> togglePostLike({
    required String postId,
    required bool currentlyLiked,
  });

  Future<List<CommentEntity>> getComments(String postId);

  Future<void> createComment({
    required String postId,
    required String content,
  });

  Future<void> updateComment({
    required String commentId,
    required String content,
  });

  Future<void> deleteComment(String commentId);
}
