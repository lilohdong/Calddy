import '../../../../core/usecase/usecase.dart';
import '../entities/comment_entity.dart';
import '../repositories/feed_repository.dart';

class GetCommentsParams {
  final String postId;
  const GetCommentsParams({required this.postId});
}

class GetCommentsUseCase
    implements UseCase<List<CommentEntity>, GetCommentsParams> {
  GetCommentsUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<List<CommentEntity>> call(GetCommentsParams params) =>
      _repository.getComments(params.postId);
}
