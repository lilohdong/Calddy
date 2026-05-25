import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/midpoint_result_model.dart';
import '../models/place_model.dart';
import 'map_remote_datasource.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient _supabase;

  MapRemoteDataSourceImpl(this._supabase);

  @override
  Future<MidpointResultModel> calculateMidpoint(String appointmentId) async {
    final response = await _supabase.functions.invoke(
      'calculate-midpoint',
      body: {'appointment_id': appointmentId},
    );
    if (response.status != 200) {
      throw FunctionException(
        status: response.status,
        details: response.data?.toString(),
      );
    }
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
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'radius': radius,
    };
    if (keyword != null) body['keyword'] = keyword;

    final response = await _supabase.functions.invoke(
      'search-places',
      body: body,
    );
    if (response.status != 200) {
      throw FunctionException(
        status: response.status,
        details: response.data?.toString(),
      );
    }
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
