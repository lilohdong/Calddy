import '../models/event_model.dart';

abstract interface class CalendarRemoteDataSource {
  Future<List<EventModel>> getEventsByDateRange(DateTime start, DateTime end);
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<EventModel> completeEvent(String eventId);
}
