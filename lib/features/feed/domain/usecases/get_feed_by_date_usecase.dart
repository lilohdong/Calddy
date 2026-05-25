import '../../../../core/usecase/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class GetFeedByDateParams {
  final DateTime date;
  const GetFeedByDateParams({required this.date});
}

class GetFeedByDateUseCase
    implements UseCase<List<PostEntity>, GetFeedByDateParams> {
  GetFeedByDateUseCase(this._repository);
  final FeedRepository _repository;

  @override
  Future<List<PostEntity>> call(GetFeedByDateParams params) =>
      _repository.getFeedByDate(params.date);
}
