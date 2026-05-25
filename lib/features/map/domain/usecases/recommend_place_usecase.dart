import '../../../../core/usecase/usecase.dart';
import '../entities/midpoint_result_entity.dart';
import '../entities/recommendation_result_entity.dart';
import '../repositories/map_repository.dart';

class RecommendPlaceParams {
  final MidpointResultEntity midpoint;
  const RecommendPlaceParams({required this.midpoint});
}

class RecommendPlaceUseCase
    implements UseCase<RecommendationResultEntity, RecommendPlaceParams> {
  final MapRepository _repository;
  const RecommendPlaceUseCase(this._repository);

  @override
  Future<RecommendationResultEntity> call(RecommendPlaceParams params) =>
      _repository.recommendPlace(params.midpoint);
}
