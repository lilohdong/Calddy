import '../../domain/entities/midpoint_result_entity.dart';
import '../models/midpoint_result_model.dart';
import '../models/recommendation_result_model.dart';

abstract interface class MapRemoteDataSource {
  Future<MidpointResultModel> calculateMidpoint(String appointmentId);
  Future<RecommendationResultModel> recommendPlace(MidpointResultEntity midpoint);
}
