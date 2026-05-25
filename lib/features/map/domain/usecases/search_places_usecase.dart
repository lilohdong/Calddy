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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchPlacesParams &&
          lat == other.lat &&
          lng == other.lng &&
          keyword == other.keyword &&
          radius == other.radius;

  @override
  int get hashCode => Object.hash(lat, lng, keyword, radius);
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
