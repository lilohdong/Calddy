import 'dart:typed_data';

import '../models/drawing_model.dart';

abstract interface class DrawingRemoteDataSource {
  Future<DrawingModel> saveDrawing(DrawingModel drawing);
  Future<DrawingModel?> getDrawingByDate(DateTime date);
  Future<Map<String, String?>> getDrawingThumbnailsForMonth(int year, int month);

  /// PNG 바이트를 drawings 버킷에 업로드하고 공개 URL을 반환한다.
  /// [date] 형식: 'yyyy-MM-dd'
  Future<String> uploadThumbnail(Uint8List bytes, String date);
}
