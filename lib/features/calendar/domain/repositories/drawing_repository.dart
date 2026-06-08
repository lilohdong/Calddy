import 'dart:typed_data';

import '../entities/drawing_entity.dart';

abstract interface class DrawingRepository {
  Future<DrawingEntity> saveDrawing(DrawingEntity drawing);
  Future<DrawingEntity?> getDrawingByDate(DateTime date);

  /// PNG 바이트를 drawings 버킷에 업로드하고 공개 URL을 반환한다.
  Future<String> uploadThumbnail(Uint8List bytes, String date);
}
