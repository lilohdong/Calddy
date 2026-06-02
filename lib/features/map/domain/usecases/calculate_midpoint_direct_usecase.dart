import '../../../../core/usecase/usecase.dart';
import '../entities/location_input.dart';
import '../entities/midpoint_result_entity.dart';
import '../repositories/map_repository.dart';

class CalculateMidpointDirectParams {
  final List<LocationInput> locations;
  const CalculateMidpointDirectParams({required this.locations});
}

class CalculateMidpointDirectUseCase
    implements UseCase<MidpointResultEntity, CalculateMidpointDirectParams> {
  final MapRepository _repository;
  const CalculateMidpointDirectUseCase(this._repository);

  @override
  Future<MidpointResultEntity> call(CalculateMidpointDirectParams params) =>
      _repository.calculateMidpointDirect(params.locations);
}
