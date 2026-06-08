import 'invite_entity.dart';

class AppointmentEntity {
  final String id;
  final String eventId;
  final String creatorId;
  final String? suggestedPlace;
  final List<InviteEntity> invites;
  final DateTime createdAt;
  final String? eventTitle;
  final DateTime? eventStartAt;
  final DateTime? eventEndAt;
  final String? eventLocation;

  const AppointmentEntity({
    required this.id,
    required this.eventId,
    required this.creatorId,
    this.suggestedPlace,
    this.invites = const [],
    required this.createdAt,
    this.eventTitle,
    this.eventStartAt,
    this.eventEndAt,
    this.eventLocation,
  });
}
