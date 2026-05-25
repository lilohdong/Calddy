import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/recommendation_result_entity.dart';

abstract interface class MapRemoteDataSource {
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId);
  Future<RecommendationResultEntity> recommendPlace(MidpointResultEntity midpoint);
}
