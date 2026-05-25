import '../../../../core/usecase/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class CreatePostParams {
  final String? content;
  final List<int>? imageBytes;
  final String? imageExtension;
  final PostVisibility visibility;
  final DateTime feedDate;
  final String? eventId;

  const CreatePostParams({
    this.content,
    this.imageBytes,
    this.imageExtension,
    required this.visibility,
    required this.feedDate,
    this.eventId,
  });
}

class CreatePostUseCase implements UseCase<void, CreatePostParams> {
  CreatePostUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<void> call(CreatePostParams params) => _repository.createPost(
        content: params.content,
        imageBytes: params.imageBytes,
        imageExtension: params.imageExtension,
        visibility: params.visibility,
        feedDate: params.feedDate,
        eventId: params.eventId,
      );
}
