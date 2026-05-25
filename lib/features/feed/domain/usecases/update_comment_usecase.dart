import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class UpdateCommentParams {
  final String commentId;
  final String content;

  const UpdateCommentParams({
    required this.commentId,
    required this.content,
  });
}

class UpdateCommentUseCase implements UseCase<void, UpdateCommentParams> {
  UpdateCommentUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(UpdateCommentParams params) => _repository.updateComment(
        commentId: params.commentId,
        content: params.content,
      );
}
