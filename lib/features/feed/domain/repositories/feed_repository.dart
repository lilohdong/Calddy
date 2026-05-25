import '../entities/post_entity.dart';

abstract class FeedRepository {
  /// 날짜 기준 피드 리스트 조회 (최신 20개)
  Future<List<PostEntity>> getFeedByDate(DateTime date);

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
}
