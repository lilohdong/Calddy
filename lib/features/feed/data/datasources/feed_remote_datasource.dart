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
}
