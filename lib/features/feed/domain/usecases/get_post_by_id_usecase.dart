import '../../../../core/usecase/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class GetPostByIdUseCase implements UseCase<PostEntity, String> {
  final FeedRepository _repository;
  const GetPostByIdUseCase(this._repository);

  @override
  Future<PostEntity> call(String postId) => _repository.getPostById(postId);
}
