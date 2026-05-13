import '../entities/drawing_entity.dart';

abstract interface class DrawingRepository {
  Future<DrawingEntity> saveDrawing(DrawingEntity drawing);
  Future<DrawingEntity?> getDrawingByDate(DateTime date);
}
