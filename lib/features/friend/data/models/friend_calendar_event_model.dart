import '../../domain/entities/friend_calendar_event_entity.dart';

class FriendCalendarEventModel extends FriendCalendarEventEntity {
  const FriendCalendarEventModel({
    required super.id,
    required super.title,
    required super.startAt,
    required super.endAt,
    required super.color,
  });

  factory FriendCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return FriendCalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      color: json['color'] as String? ?? '#9E9E9E',
    );
  }
}
