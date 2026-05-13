import 'event_entity.dart';

class CalendarData {
  final List<EventEntity> events;
  final List<EventEntity> habits;
  final List<EventEntity> ranges;

  const CalendarData({
    required this.events,
    this.habits = const [],
    this.ranges = const [],
  });
}
