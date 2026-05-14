import 'package:calddy/core/usecase/usecase.dart';
import '../entities/drawing_entity.dart';
import '../repositories/drawing_repository.dart';

class SaveDrawingParams {
  final DrawingEntity drawing;
  const SaveDrawingParams({required this.drawing});
}

class SaveDrawingUseCase implements UseCase<DrawingEntity, SaveDrawingParams> {
  final DrawingRepository _repository;
  SaveDrawingUseCase(this._repository);

  @override
  Future<DrawingEntity> call(SaveDrawingParams params) =>
      _repository.saveDrawing(params.drawing);
}
