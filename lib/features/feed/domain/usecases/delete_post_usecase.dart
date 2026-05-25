import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class DeletePostParams {
  final String postId;
  const DeletePostParams({required this.postId});
}

class DeletePostUseCase implements UseCase<void, DeletePostParams> {
  DeletePostUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(DeletePostParams params) =>
      _repository.deletePost(params.postId);
}
