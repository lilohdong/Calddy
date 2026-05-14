enum EventStatus { pending, done }

enum EventVisibility { public, private }

/// 캘린더 아이템 종류 (P2)
enum EventType { event, habit, range }

/// 반복 규칙 (P2)
enum RecurrenceType { daily, weekly, monthly }

// sentinel: copyWith에서 "변경하지 않음"을 null과 구별하기 위한 상수
const Object _keep = Object();

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

  // P2 fields
  final EventType eventType;
  final RecurrenceType? recurrenceType;
  final List<int>? recurrenceDays;
  final DateTime? recurrenceEndDate;
  final String? parentEventId;

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
    this.eventType = EventType.event,
    this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceEndDate,
    this.parentEventId,
  });

  EventEntity copyWith({
    String? id,
    String? userId,
    String? title,
    Object? location = _keep,
    Object? locationLat = _keep,
    Object? locationLng = _keep,
    DateTime? startAt,
    DateTime? endAt,
    String? color,
    bool? isDday,
    Object? memo = _keep,
    Object? notifyBeforeMin = _keep,
    EventStatus? status,
    Object? appointmentId = _keep,
    EventVisibility? visibility,
    DateTime? createdAt,
    EventType? eventType,
    Object? recurrenceType = _keep,
    Object? recurrenceDays = _keep,
    Object? recurrenceEndDate = _keep,
    Object? parentEventId = _keep,
  }) {
    return EventEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      location: identical(location, _keep) ? this.location : location as String?,
      locationLat: identical(locationLat, _keep) ? this.locationLat : locationLat as double?,
      locationLng: identical(locationLng, _keep) ? this.locationLng : locationLng as double?,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      color: color ?? this.color,
      isDday: isDday ?? this.isDday,
      memo: identical(memo, _keep) ? this.memo : memo as String?,
      notifyBeforeMin: identical(notifyBeforeMin, _keep) ? this.notifyBeforeMin : notifyBeforeMin as int?,
      status: status ?? this.status,
      appointmentId: identical(appointmentId, _keep) ? this.appointmentId : appointmentId as String?,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      recurrenceType: identical(recurrenceType, _keep) ? this.recurrenceType : recurrenceType as RecurrenceType?,
      recurrenceDays: identical(recurrenceDays, _keep) ? this.recurrenceDays : recurrenceDays as List<int>?,
      recurrenceEndDate: identical(recurrenceEndDate, _keep) ? this.recurrenceEndDate : recurrenceEndDate as DateTime?,
      parentEventId: identical(parentEventId, _keep) ? this.parentEventId : parentEventId as String?,
    );
  }
}
