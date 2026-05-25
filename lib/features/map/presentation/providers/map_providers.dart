import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/map_remote_datasource.dart';
import '../../data/datasources/map_remote_datasource_impl.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/calculate_midpoint_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';

// 1. DataSource
final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>(
  (ref) => MapRemoteDataSourceImpl(Supabase.instance.client),
);

// 2. Repository
final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepositoryImpl(
    remoteDataSource: ref.watch(mapRemoteDataSourceProvider),
  ),
);

// 3. UseCases
final calculateMidpointUseCaseProvider = Provider(
  (ref) => CalculateMidpointUseCase(ref.watch(mapRepositoryProvider)),
);

final searchPlacesUseCaseProvider = Provider(
  (ref) => SearchPlacesUseCase(ref.watch(mapRepositoryProvider)),
);

// 4. State Providers

/// 약속 ID별 중간 지점 계산 결과
final midpointProvider = FutureProvider.autoDispose
    .family<MidpointResultEntity, String>((ref, appointmentId) {
  final useCase = ref.watch(calculateMidpointUseCaseProvider);
  return useCase(CalculateMidpointParams(appointmentId: appointmentId));
});

/// 좌표 + 키워드로 장소 검색
final searchPlacesProvider = FutureProvider.autoDispose
    .family<List<PlaceEntity>, SearchPlacesParams>((ref, params) {
  final useCase = ref.watch(searchPlacesUseCaseProvider);
  return useCase(params);
});
