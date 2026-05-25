import 'event_entity.dart';
import 'holiday_entity.dart';

class CalendarData {
  final List<EventEntity> events;
  final List<EventEntity> habits;
  final List<EventEntity> ranges;
  final List<HolidayEntity> holidays;

  const CalendarData({
    required this.events,
    this.habits = const [],
    this.ranges = const [],
    this.holidays = const [],
  });
}
