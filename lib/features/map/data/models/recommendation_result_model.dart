import '../../domain/entities/recommendation_result_entity.dart';
import 'place_model.dart';

class RecommendationResultModel extends RecommendationResultEntity {
  const RecommendationResultModel({
    required super.recommendedKeyword,
    required super.places,
  });

  factory RecommendationResultModel.fromJson(Map<String, dynamic> json) =>
      RecommendationResultModel(
        recommendedKeyword: json['recommendedKeyword'] as String,
        places: (json['places'] as List<dynamic>)
            .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
