import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/map_remote_datasource.dart';
import '../../data/datasources/map_remote_datasource_impl.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/calculate_midpoint_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';

/// 맵 데이터 소스 프로바이더
final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>((ref) {
  return MapRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

/// 맵 리포지토리 프로바이더
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepositoryImpl(
    remoteDataSource: ref.watch(mapRemoteDataSourceProvider),
  );
});

// ── UseCase 프로바이더 ──────────────────────────────────────────

final calculateMidpointUseCaseProvider = Provider<CalculateMidpointUseCase>((ref) {
  return CalculateMidpointUseCase(ref.watch(mapRepositoryProvider));
});

final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>((ref) {
  return SearchPlacesUseCase(ref.watch(mapRepositoryProvider));
});
