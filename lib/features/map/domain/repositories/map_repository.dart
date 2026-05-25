import '../entities/midpoint_result_entity.dart';
import '../entities/recommendation_result_entity.dart';

abstract interface class MapRepository {
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId);
  Future<RecommendationResultEntity> recommendPlace(MidpointResultEntity midpoint);
}
