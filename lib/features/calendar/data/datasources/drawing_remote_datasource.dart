import '../models/drawing_model.dart';

abstract interface class DrawingRemoteDataSource {
  Future<DrawingModel> saveDrawing(DrawingModel drawing);
  Future<DrawingModel?> getDrawingByDate(DateTime date);
}
