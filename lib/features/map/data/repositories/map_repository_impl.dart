import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/location_input.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/recommendation_result_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _dataSource;
  const MapRepositoryImpl(this._dataSource);

  @override
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId) =>
      _guard(() => _dataSource.calculateMidpoint(appointmentId));

  @override
  Future<MidpointResultEntity> calculateMidpointDirect(
          List<LocationInput> locations) =>
      _guard(() => _dataSource.calculateMidpointDirect(locations));

  @override
  Future<RecommendationResultEntity> recommendPlace(
    MidpointResultEntity midpoint,
  ) =>
      _guard(() => _dataSource.recommendPlace(midpoint));

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FunctionException catch (e) {
      if (e.status == 404) throw const MapAppointmentNotFoundFailure();
      // Edge Function이 반환한 에러 메시지 추출
      final detail = e.details;
      String msg;
      if (detail is Map) {
        msg = detail['error']?.toString() ?? detail.toString();
      } else {
        msg = detail?.toString() ?? e.toString();
      }
      if (e.status == 422) throw MapApiFailure(msg);
      throw MapApiFailure('[${e.status}] $msg');
    } on AuthException {
      throw const MapSessionExpiredFailure();
    } catch (e) {
      throw MapUnknownFailure(e.toString());
    }
  }
}
