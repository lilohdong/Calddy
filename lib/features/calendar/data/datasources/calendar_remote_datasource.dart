import '../models/event_model.dart';
import '../models/holiday_model.dart';

abstract interface class CalendarRemoteDataSource {
  Future<List<EventModel>> getEventsByDateRange(DateTime start, DateTime end);
  Future<List<HolidayModel>> getHolidaysByRange(DateTime start, DateTime end);
  Future<EventModel> createEvent(EventModel event);
  // 반복 인스턴스 batch INSERT
  Future<List<EventModel>> createEvents(List<EventModel> events);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  // 특정 parent 기준 from 이후 인스턴스 전부 삭제 (이후 전체 수정용)
  Future<void> deleteRecurringFrom(String parentOrEventId, DateTime from);
  Future<EventModel> completeEvent(String eventId);
}
