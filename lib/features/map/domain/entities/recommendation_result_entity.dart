import 'place_entity.dart';

class RecommendationResultEntity {
  final String recommendedKeyword;
  final List<PlaceEntity> places;

  const RecommendationResultEntity({
    required this.recommendedKeyword,
    required this.places,
  });
}
