import '../../../../core/usecase/usecase.dart';
import '../entities/place_entity.dart';
import '../repositories/map_repository.dart';

class SearchPlacesParams {
  final double lat;
  final double lng;
  final String? keyword;
  final int radius;

  const SearchPlacesParams({
    required this.lat,
    required this.lng,
    this.keyword,
    this.radius = 1000,
  });
}

class SearchPlacesUseCase
    implements UseCase<List<PlaceEntity>, SearchPlacesParams> {
  final MapRepository _repository;
  SearchPlacesUseCase(this._repository);

  @override
  Future<List<PlaceEntity>> call(SearchPlacesParams params) =>
      _repository.searchPlaces(
        lat: params.lat,
        lng: params.lng,
        keyword: params.keyword,
        radius: params.radius,
      );
}
