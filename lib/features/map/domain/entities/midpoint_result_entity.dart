class ParticipantTravel {
  final String userId;
  final String nickname;
  final int? travelMinutes;

  const ParticipantTravel({
    required this.userId,
    required this.nickname,
    this.travelMinutes,
  });
}

class MidpointResultEntity {
  final double lat;
  final double lng;
  final int iterationCount;
  final List<ParticipantTravel> participants;

  const MidpointResultEntity({
    required this.lat,
    required this.lng,
    required this.iterationCount,
    required this.participants,
  });

  @override
  bool operator ==(Object other) =>
      other is MidpointResultEntity &&
      other.lat == lat &&
      other.lng == lng &&
      other.iterationCount == iterationCount;

  @override
  int get hashCode => Object.hash(lat, lng, iterationCount);
}
