class PlaceEntity {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceFromMidpoint;

  const PlaceEntity({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceFromMidpoint,
  });
}
