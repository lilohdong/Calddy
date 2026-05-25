import 'package:calddy/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event_model.dart';
import '../models/holiday_model.dart';
import 'calendar_remote_datasource.dart';

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final SupabaseClient _client;

  CalendarRemoteDataSourceImpl(this._client);

  @override
  Future<List<EventModel>> getEventsByDateRange(
      DateTime start, DateTime end) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');

    // 범위와 겹치는 이벤트: start_at < rangeEnd AND end_at > rangeStart
    // (start_at 기준 단순 필터 시 다중일 이벤트가 누락됨)
    final rows = await _client
        .from(SupabaseConstants.events)
        .select()
        .eq('user_id', userId)
        .lt('start_at', end.toIso8601String())
        .gt('end_at', start.toIso8601String())
        .order('start_at');
    return rows.map((r) => EventModel.fromJson(r)).toList();
  }

  @override
  Future<List<HolidayModel>> getHolidaysByRange(
      DateTime start, DateTime end) async {
    final startStr =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from(SupabaseConstants.holidays)
        .select('date, name')
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date');
    return rows.map((r) => HolidayModel.fromJson(r)).toList();
  }

  @override
  Future<EventModel> createEvent(EventModel event) async {
    final row = await _client
        .from(SupabaseConstants.events)
        .insert(event.toJson())
        .select()
        .single();
    return EventModel.fromJson(row);
  }

  @override
  Future<EventModel> updateEvent(EventModel event) async {
    final row = await _client
        .from(SupabaseConstants.events)
        .update(event.toJsonForUpdate())
        .eq('id', event.id)
        .select()
        .single();
    return EventModel.fromJson(row);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _client.from(SupabaseConstants.events).delete().eq('id', eventId);
  }

  @override
  Future<List<EventModel>> createEvents(List<EventModel> events) async {
    if (events.isEmpty) return [];
    final rows = await _client
        .from(SupabaseConstants.events)
        .insert(events.map((e) => e.toJson()).toList())
        .select();
    return rows.map((r) => EventModel.fromJson(r)).toList();
  }

  @override
  Future<void> deleteRecurringFrom(String parentOrEventId, DateTime from) async {
    await _client
        .from(SupabaseConstants.events)
        .delete()
        .or('id.eq.$parentOrEventId,parent_event_id.eq.$parentOrEventId')
        .gte('start_at', from.toIso8601String());
  }

  @override
  Future<EventModel> completeEvent(String eventId) async {
    final row = await _client
        .from(SupabaseConstants.events)
        .update({'status': 'done'})
        .eq('id', eventId)
        .select()
        .single();
    return EventModel.fromJson(row);
  }
}
