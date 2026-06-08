import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/repositories/drawing_repository.dart';
import '../datasources/drawing_remote_datasource.dart';
import '../models/drawing_model.dart';

class DrawingRepositoryImpl implements DrawingRepository {
  final DrawingRemoteDataSource _dataSource;

  DrawingRepositoryImpl({required DrawingRemoteDataSource remoteDataSource})
      : _dataSource = remoteDataSource;

  @override
  Future<DrawingEntity> saveDrawing(DrawingEntity drawing) =>
      _guard(() => _dataSource.saveDrawing(DrawingModel.fromEntity(drawing)));

  @override
  Future<DrawingEntity?> getDrawingByDate(DateTime date) =>
      _guard(() => _dataSource.getDrawingByDate(date));

  @override
  Future<String> uploadThumbnail(Uint8List bytes, String date) =>
      _guard(() => _dataSource.uploadThumbnail(bytes, date));

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AuthException {
      throw const DrawingSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw DrawingDatabaseFailure(e.message);
    } on StorageException catch (e) {
      throw DrawingStorageFailure(e.message);
    } on DrawingFailure {
      rethrow;
    } catch (_) {
      throw const DrawingUnknownFailure();
    }
  }
}
