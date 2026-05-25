import '../../domain/entities/place_entity.dart';

class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.placeId,
    required super.name,
    required super.address,
    required super.lat,
    required super.lng,
    super.distanceFromMidpoint,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceFromMidpoint: json['distanceFromMidpoint'] != null
          ? (json['distanceFromMidpoint'] as num).toDouble()
          : null,
    );
  }
}
