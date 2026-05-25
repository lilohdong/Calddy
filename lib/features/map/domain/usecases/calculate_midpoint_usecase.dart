import '../../../../core/usecase/usecase.dart';
import '../entities/midpoint_result_entity.dart';
import '../repositories/map_repository.dart';

class CalculateMidpointParams {
  final String appointmentId;
  const CalculateMidpointParams({required this.appointmentId});
}

class CalculateMidpointUseCase
    implements UseCase<MidpointResultEntity, CalculateMidpointParams> {
  final MapRepository _repository;
  CalculateMidpointUseCase(this._repository);

  @override
  Future<MidpointResultEntity> call(CalculateMidpointParams params) =>
      _repository.calculateMidpoint(params.appointmentId);
}
