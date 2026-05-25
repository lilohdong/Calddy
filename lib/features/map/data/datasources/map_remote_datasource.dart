import '../models/midpoint_result_model.dart';
import '../models/place_model.dart';

abstract interface class MapRemoteDataSource {
  Future<MidpointResultModel> calculateMidpoint(String appointmentId);

  Future<List<PlaceModel>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius,
  });
}
