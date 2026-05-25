import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class TogglePostLikeParams {
  final String postId;
  final bool currentlyLiked;

  const TogglePostLikeParams({
    required this.postId,
    required this.currentlyLiked,
  });
}

class TogglePostLikeUseCase implements UseCase<void, TogglePostLikeParams> {
  TogglePostLikeUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(TogglePostLikeParams params) => _repository.togglePostLike(
        postId: params.postId,
        currentlyLiked: params.currentlyLiked,
      );
}
