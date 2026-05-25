import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/recommendation_result_entity.dart';
import '../models/midpoint_result_model.dart';
import '../models/recommendation_result_model.dart';
import 'map_remote_datasource.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient _client;
  const MapRemoteDataSourceImpl(this._client);

  @override
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId) async {
    final res = await _client.functions.invoke(
      'calculate-midpoint',
      body: {'appointment_id': appointmentId},
    );
    return MidpointResultModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<RecommendationResultEntity> recommendPlace(
    MidpointResultEntity midpoint,
  ) async {
    final res = await _client.functions.invoke(
      'recommend-place',
      body: {
        'lat': midpoint.lat,
        'lng': midpoint.lng,
        'participants': midpoint.participants
            .map(
              (p) => {
                'userId': p.userId,
                'nickname': p.nickname,
                'travelMinutes': p.travelMinutes,
              },
            )
            .toList(),
      },
    );
    return RecommendationResultModel.fromJson(res.data as Map<String, dynamic>);
  }
}
