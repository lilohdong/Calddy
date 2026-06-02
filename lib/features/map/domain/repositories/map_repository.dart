import '../entities/location_input.dart';
import '../entities/midpoint_result_entity.dart';
import '../entities/recommendation_result_entity.dart';

abstract interface class MapRepository {
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId);
  Future<MidpointResultEntity> calculateMidpointDirect(List<LocationInput> locations);
  Future<RecommendationResultEntity> recommendPlace(MidpointResultEntity midpoint);
}
