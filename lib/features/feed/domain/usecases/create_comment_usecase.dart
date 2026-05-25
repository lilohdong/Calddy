import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class CreateCommentParams {
  final String postId;
  final String content;

  const CreateCommentParams({
    required this.postId,
    required this.content,
  });
}

class CreateCommentUseCase implements UseCase<void, CreateCommentParams> {
  CreateCommentUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(CreateCommentParams params) => _repository.createComment(
        postId: params.postId,
        content: params.content,
      );
}
