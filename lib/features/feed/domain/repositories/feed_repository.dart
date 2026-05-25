import '../entities/comment_entity.dart';
import '../entities/post_entity.dart';
import '../entities/post_liker_entity.dart';

abstract class FeedRepository {
  /// 날짜 기준 피드 리스트 조회 (최신 20개, isLikedByMe 포함)
  /// cursor: 마지막으로 받은 게시글의 createdAt (null이면 첫 페이지)
  Future<List<PostEntity>> getFeedByDate(DateTime date, {DateTime? cursor});

  /// Realtime: 댓글 변경사항 구독
  Stream<List<CommentEntity>> watchComments(String postId);

  /// 게시글 생성 (content/imageBytes 중 하나 이상 필수)
  Future<void> createPost({
    String? content,
    List<int>? imageBytes,
    String? imageExtension,
    required PostVisibility visibility,
    required DateTime feedDate,
    String? eventId,
  });

  /// 게시글 수정 (content, visibility)
  Future<void> updatePost({
    required String postId,
    String? content,
    required PostVisibility visibility,
  });

  /// 게시글 삭제 (Storage 이미지 포함)
  Future<void> deletePost(String postId);

  // ── P2 ────────────────────────────────────────────────────────────────────

  /// 좋아요 토글 (currentlyLiked=true 이면 취소, false 이면 추가)
  Future<void> togglePostLike({
    required String postId,
    required bool currentlyLiked,
  });

  /// 게시글 댓글 목록 조회 (created_at 오름차순)
  Future<List<CommentEntity>> getComments(String postId);

  /// 댓글 생성
  Future<void> createComment({
    required String postId,
    required String content,
  });

  /// 댓글 수정 (본인 한정)
  Future<void> updateComment({
    required String commentId,
    required String content,
  });

  /// 댓글 삭제 (본인 한정)
  Future<void> deleteComment(String commentId);

  /// 특정 게시글에 좋아요 누른 사용자 목록 조회
  Future<List<PostLikerEntity>> getPostLikers(String postId);
}
