import 'event_entity.dart';

class CalendarData {
  final List<EventEntity> events;
  // P2에서 HabitEntity / RangeEntity 구현 후 List<dynamic> → 구체 타입으로 교체
  final List<dynamic> habits;
  final List<dynamic> ranges;

  const CalendarData({
    required this.events,
    this.habits = const [],
    this.ranges = const [],
  });
}
