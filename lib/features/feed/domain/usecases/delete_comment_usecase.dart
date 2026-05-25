import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class DeleteCommentParams {
  final String commentId;
  const DeleteCommentParams({required this.commentId});
}

class DeleteCommentUseCase implements UseCase<void, DeleteCommentParams> {
  DeleteCommentUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(DeleteCommentParams params) =>
      _repository.deleteComment(params.commentId);
}
