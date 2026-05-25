import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/map_remote_datasource_impl.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/recommendation_result_entity.dart';
import '../../domain/usecases/calculate_midpoint_usecase.dart';
import '../../domain/usecases/recommend_place_usecase.dart';

final _mapDataSourceProvider = Provider(
  (ref) => MapRemoteDataSourceImpl(Supabase.instance.client),
);

final _mapRepositoryProvider = Provider(
  (ref) => MapRepositoryImpl(ref.watch(_mapDataSourceProvider)),
);

final _calculateMidpointUseCaseProvider = Provider(
  (ref) => CalculateMidpointUseCase(ref.watch(_mapRepositoryProvider)),
);

final _recommendPlaceUseCaseProvider = Provider(
  (ref) => RecommendPlaceUseCase(ref.watch(_mapRepositoryProvider)),
);

/// appointmentId → MidpointResultEntity
final midpointProvider = FutureProvider.autoDispose
    .family<MidpointResultEntity, String>((ref, appointmentId) {
  return ref
      .read(_calculateMidpointUseCaseProvider)
      .call(CalculateMidpointParams(appointmentId: appointmentId));
});

/// MidpointResultEntity → RecommendationResultEntity
/// MidpointResultEntity에 participants까지 포함한 ==·hashCode 구현 필요
final recommendPlaceProvider = FutureProvider.autoDispose
    .family<RecommendationResultEntity, MidpointResultEntity>((ref, midpoint) {
  return ref
      .read(_recommendPlaceUseCaseProvider)
      .call(RecommendPlaceParams(midpoint: midpoint));
});
