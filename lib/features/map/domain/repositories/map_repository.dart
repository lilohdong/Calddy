import '../entities/midpoint_result_entity.dart';
import '../entities/place_entity.dart';

abstract interface class MapRepository {
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId);

  Future<List<PlaceEntity>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  });
}
