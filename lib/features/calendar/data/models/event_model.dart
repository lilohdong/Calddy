import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.userId,
    required super.title,
    super.location,
    super.locationLat,
    super.locationLng,
    required super.startAt,
    required super.endAt,
    required super.color,
    required super.isDday,
    super.memo,
    super.notifyBeforeMin,
    required super.status,
    super.appointmentId,
    required super.visibility,
    required super.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        location: json['location'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        startAt: DateTime.parse(json['start_at'] as String),
        endAt: DateTime.parse(json['end_at'] as String),
        color: json['color'] as String,
        isDday: json['is_dday'] as bool,
        memo: json['memo'] as String?,
        notifyBeforeMin: json['notify_before_min'] as int?,
        status: EventStatus.values.byName(json['status'] as String),
        appointmentId: json['appointment_id'] as String?,
        visibility: EventVisibility.values.byName(json['visibility'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  factory EventModel.fromEntity(EventEntity e) => EventModel(
        id: e.id,
        userId: e.userId,
        title: e.title,
        location: e.location,
        locationLat: e.locationLat,
        locationLng: e.locationLng,
        startAt: e.startAt,
        endAt: e.endAt,
        color: e.color,
        isDday: e.isDday,
        memo: e.memo,
        notifyBeforeMin: e.notifyBeforeMin,
        status: e.status,
        appointmentId: e.appointmentId,
        visibility: e.visibility,
        createdAt: e.createdAt,
      );

  // id는 DB auto-generate이므로 INSERT payload에 미포함
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'location': location,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'color': color,
        'is_dday': isDday,
        'memo': memo,
        'notify_before_min': notifyBeforeMin,
        'status': status.name,
        'appointment_id': appointmentId,
        'visibility': visibility.name,
      };
}
