import '../models/comment_model.dart';
import '../models/post_liker_model.dart';
import '../models/post_model.dart';

abstract class FeedRemoteDataSource {
  /// cursor: 마지막으로 받은 게시글의 createdAt (null이면 첫 페이지)
  Future<List<PostModel>> getFeedByDate(DateTime date, {DateTime? cursor});

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

  Future<List<CommentModel>> getComments(String postId);

  Future<void> createComment({
    required String postId,
    required String content,
  });

  Future<void> updateComment({
    required String commentId,
    required String content,
  });

  Future<void> deleteComment(String commentId);

  /// Realtime: 댓글 변경사항 구독 (INSERT / UPDATE / DELETE)
  Stream<List<CommentModel>> watchComments(String postId);

  /// 특정 게시글에 좋아요 누른 사용자 목록 조회
  Future<List<PostLikerModel>> getPostLikers(String postId);
}
