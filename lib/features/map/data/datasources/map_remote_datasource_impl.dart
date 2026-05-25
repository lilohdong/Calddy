import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/midpoint_result_model.dart';
import '../models/place_model.dart';
import 'map_remote_datasource.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient _client;
  MapRemoteDataSourceImpl(this._client);

  @override
  Future<MidpointResultModel> calculateMidpoint(String appointmentId) async {
    final response = await _client.functions.invoke(
      'calculate-midpoint',
      body: {'appointment_id': appointmentId},
    );
    return MidpointResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PlaceModel>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  }) async {
    final response = await _client.functions.invoke(
      'search-places',
      body: {
        'lat': lat,
        'lng': lng,
        if (keyword != null) 'keyword': keyword,
        'radius': radius,
      },
    );
    final list = response.data as List;
    return list
        .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
