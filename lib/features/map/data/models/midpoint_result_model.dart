import '../../domain/entities/midpoint_result_entity.dart';

class ParticipantTravelModel extends ParticipantTravelEntity {
  const ParticipantTravelModel({
    required super.userId,
    required super.nickname,
    super.travelMinutes,
  });

  factory ParticipantTravelModel.fromJson(Map<String, dynamic> json) {
    return ParticipantTravelModel(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      travelMinutes: json['travelMinutes'] as int?,
    );
  }
}

class MidpointResultModel extends MidpointResultEntity {
  const MidpointResultModel({
    required super.lat,
    required super.lng,
    required super.participants,
  });

  factory MidpointResultModel.fromJson(Map<String, dynamic> json) {
    return MidpointResultModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      participants: (json['participants'] as List)
          .map((p) => ParticipantTravelModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
