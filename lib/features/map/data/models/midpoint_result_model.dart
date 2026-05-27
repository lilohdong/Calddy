import '../../domain/entities/midpoint_result_entity.dart';

class ParticipantTravelModel extends ParticipantTravel {
  const ParticipantTravelModel({
    required super.userId,
    required super.nickname,
    super.travelMinutes,
  });

  factory ParticipantTravelModel.fromJson(Map<String, dynamic> json) =>
      ParticipantTravelModel(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        travelMinutes: (json['travelMinutes'] as num?)?.toInt(),
      );
}

class MidpointResultModel extends MidpointResultEntity {
  const MidpointResultModel({
    required super.lat,
    required super.lng,
    required super.iterationCount,
    required super.participants,
  });

  factory MidpointResultModel.fromJson(Map<String, dynamic> json) =>
      MidpointResultModel(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        iterationCount: (json['iterationCount'] as num?)?.toInt() ?? 0,
        participants: (json['participants'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      ParticipantTravelModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
