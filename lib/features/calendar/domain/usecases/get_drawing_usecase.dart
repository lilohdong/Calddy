import 'package:calddy/core/usecase/usecase.dart';
import '../entities/drawing_entity.dart';
import '../repositories/drawing_repository.dart';

class GetDrawingParams {
  final DateTime date;
  const GetDrawingParams({required this.date});
}

class GetDrawingUseCase implements UseCase<DrawingEntity?, GetDrawingParams> {
  final DrawingRepository _repository;
  GetDrawingUseCase(this._repository);

  @override
  Future<DrawingEntity?> call(GetDrawingParams params) =>
      _repository.getDrawingByDate(params.date);
}
