import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
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
  Future<RecommendationResultEntity> recommendPlace(
    MidpointResultEntity midpoint,
  ) =>
      _guard(() => _dataSource.recommendPlace(midpoint));

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FunctionException catch (e) {
      if (e.status == 404) throw const MapAppointmentNotFoundFailure();
      if (e.status == 422) throw const NoLocationDataFailure();
      throw MapApiFailure(e.details?.toString() ?? e.toString());
    } on AuthException {
      throw const MapSessionExpiredFailure();
    } catch (e) {
      throw MapUnknownFailure(e.toString());
    }
  }
}
