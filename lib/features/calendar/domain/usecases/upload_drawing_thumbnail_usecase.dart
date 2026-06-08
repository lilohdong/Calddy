import 'dart:typed_data';

import 'package:calddy/core/usecase/usecase.dart';
import '../repositories/drawing_repository.dart';

class UploadDrawingThumbnailParams {
  final Uint8List bytes;

  /// 'yyyy-MM-dd' 형식
  final String date;
  const UploadDrawingThumbnailParams({required this.bytes, required this.date});
}

class UploadDrawingThumbnailUseCase
    implements UseCase<String, UploadDrawingThumbnailParams> {
  final DrawingRepository _repository;
  UploadDrawingThumbnailUseCase(this._repository);

  @override
  Future<String> call(UploadDrawingThumbnailParams params) =>
      _repository.uploadThumbnail(params.bytes, params.date);
}
