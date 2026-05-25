class ParticipantTravel {
  final String userId;
  final String nickname;
  final int? travelMinutes;

  const ParticipantTravel({
    required this.userId,
    required this.nickname,
    this.travelMinutes,
  });

  @override
  bool operator ==(Object other) =>
      other is ParticipantTravel &&
      other.userId == userId &&
      other.nickname == nickname &&
      other.travelMinutes == travelMinutes;

  @override
  int get hashCode => Object.hash(userId, nickname, travelMinutes);
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
      other.iterationCount == iterationCount &&
      _participantsEqual(other.participants);

  bool _participantsEqual(List<ParticipantTravel> other) {
    if (other.length != participants.length) return false;
    for (var i = 0; i < participants.length; i++) {
      if (participants[i] != other[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        lat,
        lng,
        iterationCount,
        Object.hashAll(participants),
      );
}
