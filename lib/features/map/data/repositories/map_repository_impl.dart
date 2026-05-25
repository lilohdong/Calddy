import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _remoteDataSource;

  MapRepositoryImpl({required MapRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId) async {
    try {
      return await _remoteDataSource.calculateMidpoint(appointmentId);
    } on FunctionException catch (e) {
      if (e.status == 404) throw const MapAppointmentNotFoundFailure();
      throw MapServerFailure(e.details?.toString() ?? '서버 오류가 발생했습니다.');
    } catch (_) {
      throw const MapUnknownFailure();
    }
  }

  @override
  Future<List<PlaceEntity>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  }) async {
    try {
      return await _remoteDataSource.searchPlaces(
        lat: lat,
        lng: lng,
        keyword: keyword,
        radius: radius,
      );
    } on FunctionException catch (e) {
      throw MapServerFailure(e.details?.toString() ?? '장소 검색 중 오류가 발생했습니다.');
    } catch (_) {
      throw const MapUnknownFailure();
    }
  }
}
