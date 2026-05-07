import 'package:calddy/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event_model.dart';
import 'calendar_remote_datasource.dart';

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final SupabaseClient _client;

  CalendarRemoteDataSourceImpl(this._client);

  @override
  Future<List<EventModel>> getEventsByDateRange(
      DateTime start, DateTime end) async {
    final rows = await _client
        .from(SupabaseConstants.events)
        .select()
        .eq('user_id', _client.auth.currentUser!.id)
        .gte('start_at', start.toIso8601String())
        .lte('start_at', end.toIso8601String())
        .order('start_at');
    return rows.map((r) => EventModel.fromJson(r)).toList();
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
        .update(event.toJson())
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
