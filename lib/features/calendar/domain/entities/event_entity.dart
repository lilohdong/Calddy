enum EventStatus { pending, done }

enum EventVisibility { public, private }

class EventEntity {
  final String id;
  final String userId;
  final String title;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final DateTime startAt;
  final DateTime endAt;
  final String color;
  final bool isDday;
  final String? memo;
  final int? notifyBeforeMin;
  final EventStatus status;
  final String? appointmentId;
  final EventVisibility visibility;
  final DateTime createdAt;

  const EventEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.location,
    this.locationLat,
    this.locationLng,
    required this.startAt,
    required this.endAt,
    required this.color,
    required this.isDday,
    this.memo,
    this.notifyBeforeMin,
    required this.status,
    this.appointmentId,
    required this.visibility,
    required this.createdAt,
  });

  EventEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? location,
    double? locationLat,
    double? locationLng,
    DateTime? startAt,
    DateTime? endAt,
    String? color,
    bool? isDday,
    String? memo,
    int? notifyBeforeMin,
    EventStatus? status,
    String? appointmentId,
    EventVisibility? visibility,
    DateTime? createdAt,
  }) {
    return EventEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      color: color ?? this.color,
      isDday: isDday ?? this.isDday,
      memo: memo ?? this.memo,
      notifyBeforeMin: notifyBeforeMin ?? this.notifyBeforeMin,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
