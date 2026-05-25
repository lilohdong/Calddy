class ParticipantTravelEntity {
  final String userId;
  final String nickname;
  final int? travelMinutes; // null = 출발지 미설정 또는 ODsay 조회 실패

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
