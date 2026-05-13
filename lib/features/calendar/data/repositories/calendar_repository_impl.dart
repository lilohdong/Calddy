import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
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
  Future<CalendarData> getCalendarByMonth(int year, int month) =>
      _guard(() async {
        final start = DateTime(year, month, 1);
        // day 0 of month+1 = last day of current month
        final end = DateTime(year, month + 1, 0, 23, 59, 59);
        final all = await _dataSource.getEventsByDateRange(start, end);
        return _toCalendarData(all);
      });

  @override
  Future<CalendarData> getCalendarByWeek(DateTime weekStart) =>
      _guard(() async {
        final end = weekStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        final all = await _dataSource.getEventsByDateRange(weekStart, end);
        return _toCalendarData(all);
      });

  @override
  Future<EventEntity> createEvent(EventEntity event) =>
      _guard(() => _dataSource.createEvent(EventModel.fromEntity(event)));

  @override
  Future<List<EventEntity>> createHabitInstances(EventEntity template) =>
      _guard(() async {
        if (template.recurrenceType == null) {
          throw const CalendarDatabaseFailure('habit 템플릿에 recurrenceType이 없습니다.');
        }
        final endDate = template.recurrenceEndDate ??
            DateTime(template.startAt.year + 1, template.startAt.month,
                template.startAt.day);
        final dates = _generateHabitDates(
          start: template.startAt,
          type: template.recurrenceType!,
          days: template.recurrenceDays,
          end: endDate,
        );
        if (dates.isEmpty) return [];

        // 1) 첫 인스턴스 INSERT (parent, parentEventId = null)
        final duration = template.endAt.difference(template.startAt);
        final firstModel = EventModel.fromEntity(
          template.copyWith(
            startAt: dates.first,
            endAt: dates.first.add(duration),
            parentEventId: null,
          ),
        );
        final parent = await _dataSource.createEvent(firstModel);

        if (dates.length == 1) return [parent];

        // 2) 나머지 인스턴스 batch INSERT (parentEventId = parent.id)
        final remaining = dates
            .skip(1)
            .map((d) => EventModel.fromEntity(
                  template.copyWith(
                    startAt: d,
                    endAt: d.add(duration),
                    parentEventId: parent.id,
                  ),
                ))
            .toList();
        final created = await _dataSource.createEvents(remaining);
        return [parent, ...created];
      });

  @override
  Future<EventEntity> updateEvent(EventEntity event) =>
      _guard(() => _dataSource.updateEvent(EventModel.fromEntity(event)));

  @override
  Future<List<EventEntity>> updateRecurringEvent({
    required EventEntity event,
    required bool thisAndFuture,
  }) =>
      _guard(() async {
        if (!thisAndFuture) {
          final updated =
              await _dataSource.updateEvent(EventModel.fromEntity(event));
          return [updated];
        }
        // 이후 전체 수정: 이 이벤트 + 자식 인스턴스 삭제 후 재생성
        final parentId = event.parentEventId ?? event.id;
        await _dataSource.deleteRecurringFrom(parentId, event.startAt);
        return createHabitInstances(
          event.copyWith(parentEventId: null),
        );
      });

  @override
  Future<void> deleteEvent(String eventId) =>
      _guard(() => _dataSource.deleteEvent(eventId));

  @override
  Future<EventEntity> completeEvent(String eventId) =>
      _guard(() => _dataSource.completeEvent(eventId));

  // ── Private helpers ────────────────────────────────────────────────────

  CalendarData _toCalendarData(List<EventModel> all) => CalendarData(
        events: all.where((e) => e.eventType == EventType.event).toList(),
        habits: all.where((e) => e.eventType == EventType.habit).toList(),
        ranges: all.where((e) => e.eventType == EventType.range).toList(),
      );

  /// 반복 규칙에 맞는 날짜 목록 생성
  /// weekly: recurrenceDays = [0-6] (0=일, 1=월 ... 6=토)
  ///         Flutter weekday % 7 으로 변환 (일요일=7 → 0)
  /// monthly: recurrenceDays = [1-31] (매월 N일)
  List<DateTime> _generateHabitDates({
    required DateTime start,
    required RecurrenceType type,
    List<int>? days,
    required DateTime end,
  }) {
    final result = <DateTime>[];
    var cur = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!cur.isAfter(endDay)) {
      final include = switch (type) {
        RecurrenceType.daily => true,
        RecurrenceType.weekly => days?.contains(cur.weekday % 7) ?? false,
        RecurrenceType.monthly => days?.contains(cur.day) ?? false,
      };
      if (include) {
        result.add(DateTime(cur.year, cur.month, cur.day, start.hour,
            start.minute, start.second));
      }
      cur = cur.add(const Duration(days: 1));
    }
    return result;
  }

  /// DataSource 예외를 도메인 [CalendarFailure]로 변환
  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AuthException {
      throw const CalendarSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw CalendarDatabaseFailure(e.message);
    } on CalendarFailure {
      rethrow;
    } catch (_) {
      throw const CalendarUnknownFailure();
    }
  }
}
