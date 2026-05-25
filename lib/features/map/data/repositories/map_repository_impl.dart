import 'package:functions_client/functions_client.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _dataSource;

  MapRepositoryImpl({required MapRemoteDataSource remoteDataSource})
      : _dataSource = remoteDataSource;

  @override
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId) =>
      _guard(() => _dataSource.calculateMidpoint(appointmentId));

  @override
  Future<List<PlaceEntity>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  }) =>
      _guard(() => _dataSource.searchPlaces(
            lat: lat,
            lng: lng,
            keyword: keyword,
            radius: radius,
          ));

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FunctionException catch (e) {
      final body = e.details is Map<String, dynamic>
          ? e.details as Map<String, dynamic>
          : null;
      final message = body?['error'] as String? ?? e.toString();
      if (message.contains('not found')) {
        throw const MapAppointmentNotFoundFailure();
      }
      throw MapServerFailure(message);
    } catch (e) {
      if (e is MapFailure) rethrow;
      throw const MapUnknownFailure();
    }
  }
}
