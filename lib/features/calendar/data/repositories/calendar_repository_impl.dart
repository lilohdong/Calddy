import '../../domain/entities/calendar_data.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';
import '../models/event_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _dataSource;

  CalendarRepositoryImpl({required CalendarRemoteDataSource remoteDataSource})
      : _dataSource = remoteDataSource;

  @override
  Future<CalendarData> getCalendarByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    // day 0 of month+1 = last day of current month
    // e.g. DateTime(2026, 6, 0, 23, 59, 59) == DateTime(2026, 5, 31, 23, 59, 59)
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final events = await _dataSource.getEventsByDateRange(start, end);
    return CalendarData(events: events);
    // P2: habits/ranges 쿼리 추가 후 CalendarData(events, habits, ranges) 반환
  }

  @override
  Future<CalendarData> getCalendarByWeek(DateTime weekStart) async {
    final end = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    final events = await _dataSource.getEventsByDateRange(weekStart, end);
    return CalendarData(events: events);
  }

  @override
  Future<EventEntity> createEvent(EventEntity event) =>
      _dataSource.createEvent(EventModel.fromEntity(event));

  @override
  Future<EventEntity> updateEvent(EventEntity event) =>
      _dataSource.updateEvent(EventModel.fromEntity(event));

  @override
  Future<void> deleteEvent(String eventId) =>
      _dataSource.deleteEvent(eventId);

  @override
  Future<EventEntity> completeEvent(String eventId) =>
      _dataSource.completeEvent(eventId);
}
