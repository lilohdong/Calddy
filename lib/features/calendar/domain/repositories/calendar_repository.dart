import '../entities/calendar_data.dart';
import '../entities/event_entity.dart';

abstract interface class CalendarRepository {
  Future<CalendarData> getCalendarByMonth(int year, int month);
  Future<CalendarData> getCalendarByWeek(DateTime weekStart);
  Future<EventEntity> createEvent(EventEntity event);
  Future<List<EventEntity>> createHabitInstances(EventEntity template);
  Future<EventEntity> updateEvent(EventEntity event);
  Future<List<EventEntity>> updateRecurringEvent({
    required EventEntity event,
    required bool thisAndFuture,
  });
  Future<void> deleteEvent(String eventId);
  Future<EventEntity> completeEvent(String eventId);
}
