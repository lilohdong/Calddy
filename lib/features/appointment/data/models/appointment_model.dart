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
    super.eventTitle,
    super.eventStartAt,
    super.eventEndAt,
    super.eventLocation,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawInvites = json['appointment_invites'] as List<dynamic>?;
    final event = json['events'] as Map<String, dynamic>?;
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
      eventTitle: event?['title'] as String?,
      eventStartAt: event?['start_at'] != null
          ? DateTime.parse(event!['start_at'] as String)
          : null,
      eventEndAt: event?['end_at'] != null
          ? DateTime.parse(event!['end_at'] as String)
          : null,
      eventLocation: event?['location'] as String?,
    );
  }

  factory AppointmentModel.fromEntity(AppointmentEntity e) => AppointmentModel(
        id: e.id,
        eventId: e.eventId,
        creatorId: e.creatorId,
        suggestedPlace: e.suggestedPlace,
        invites: e.invites,
        createdAt: e.createdAt,
        eventTitle: e.eventTitle,
        eventStartAt: e.eventStartAt,
        eventEndAt: e.eventEndAt,
        eventLocation: e.eventLocation,
      );

  // INSERT payload: id 제외 (DB auto-generate), invites 제외
  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'creator_id': creatorId,
        'suggested_place': suggestedPlace,
      };
}
