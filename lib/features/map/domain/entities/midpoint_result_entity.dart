class ParticipantTravelEntity {
  final String userId;
  final String nickname;
  final int? travelMinutes;

  const ParticipantTravelEntity({
    required this.userId,
    required this.nickname,
    this.travelMinutes,
  });
}

class MidpointResultEntity {
  final double lat;
  final double lng;
  final List<ParticipantTravelEntity> participants;

  const MidpointResultEntity({
    required this.lat,
    required this.lng,
    required this.participants,
  });
}
