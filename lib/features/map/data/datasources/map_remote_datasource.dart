import '../../domain/entities/location_input.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../models/midpoint_result_model.dart';
import '../models/recommendation_result_model.dart';

abstract interface class MapRemoteDataSource {
  /// Mode A: appointment_id 기반 중간지점 계산
  Future<MidpointResultModel> calculateMidpoint(String appointmentId);

  /// Mode B: 주소 직접 입력 기반 중간지점 계산 (appointment 없이 사용)
  Future<MidpointResultModel> calculateMidpointDirect(List<LocationInput> locations);

  Future<RecommendationResultModel> recommendPlace(MidpointResultEntity midpoint);
}
