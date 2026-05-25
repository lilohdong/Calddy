import '../../../../core/usecase/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class UpdatePostParams {
  final String postId;
  final String? content;
  final PostVisibility visibility;

  const UpdatePostParams({
    required this.postId,
    this.content,
    required this.visibility,
  });
}

class UpdatePostUseCase implements UseCase<void, UpdatePostParams> {
  UpdatePostUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(UpdatePostParams params) => _repository.updatePost(
        postId: params.postId,
        content: params.content,
        visibility: params.visibility,
      );
}
