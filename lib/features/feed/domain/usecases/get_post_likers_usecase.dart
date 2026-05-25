import '../../../../core/usecase/usecase.dart';
import '../entities/post_liker_entity.dart';
import '../repositories/feed_repository.dart';

class GetPostLikersUseCase
    implements UseCase<List<PostLikerEntity>, String> {
  GetPostLikersUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<List<PostLikerEntity>> call(String postId) =>
      _repository.getPostLikers(postId);
}
