import '../../domain/entities/appointment_entity.dart';
import 'invite_model.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.eventId,
    required super.creatorId,
    super.suggestedPlace,
    super.invites,
    required super.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawInvites = json['appointment_invites'] as List<dynamic>?;
    return AppointmentModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      creatorId: json['creator_id'] as String,
      suggestedPlace: json['suggested_place'] as String?,
      invites: rawInvites
              ?.map((e) => InviteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory AppointmentModel.fromEntity(AppointmentEntity e) => AppointmentModel(
        id: e.id,
        eventId: e.eventId,
        creatorId: e.creatorId,
        suggestedPlace: e.suggestedPlace,
        invites: e.invites,
        createdAt: e.createdAt,
      );

  // INSERT payload: id 제외 (DB auto-generate), invites 제외
  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'creator_id': creatorId,
        'suggested_place': suggestedPlace,
      };
}
