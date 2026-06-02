import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/map_remote_datasource_impl.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/location_input.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/recommendation_result_entity.dart';
import '../../domain/usecases/calculate_midpoint_direct_usecase.dart';
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

final _calculateMidpointDirectUseCaseProvider = Provider(
  (ref) => CalculateMidpointDirectUseCase(ref.watch(_mapRepositoryProvider)),
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
final recommendPlaceProvider = FutureProvider.autoDispose
    .family<RecommendationResultEntity, MidpointResultEntity>((ref, midpoint) {
  return ref
      .read(_recommendPlaceUseCaseProvider)
      .call(RecommendPlaceParams(midpoint: midpoint));
});

/// Mode B: 주소 직접 입력 → 중간지점 계산 (appointment 없이 사용)
///
/// ⚠️  family 키로 List를 쓰면 매 build마다 새 객체 → provider 재시작 무한루프 발생.
///     String(JSON 직렬화)을 키로 사용해 동등성 문제를 회피함.
///
/// 사용: midpointDirectProvider(LocationInput.listToKey(locations))
final midpointDirectProvider = FutureProvider.autoDispose
    .family<MidpointResultEntity, String>((ref, locationsJson) {
  final locations = (jsonDecode(locationsJson) as List)
      .map((e) => LocationInput.fromJson(e as Map<String, dynamic>))
      .toList();
  return ref
      .read(_calculateMidpointDirectUseCaseProvider)
      .call(CalculateMidpointDirectParams(locations: locations));
});
