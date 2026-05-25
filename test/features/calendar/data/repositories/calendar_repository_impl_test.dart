import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calddy/features/calendar/data/models/event_model.dart';
import 'package:calddy/features/calendar/data/models/holiday_model.dart';
import 'package:calddy/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockCalendarRemoteDataSource extends Mock
    implements CalendarRemoteDataSource {}

class FakeEventModel extends Fake implements EventModel {}

EventModel _dummyModel({String id = 'event-1'}) => EventModel(
      id: id,
      userId: 'user-1',
      title: '테스트',
      startAt: DateTime(2026, 5, 7, 10),
      endAt: DateTime(2026, 5, 7, 11),
      color: '#4A90D9',
      isDday: false,
      status: EventStatus.pending,
      visibility: EventVisibility.public,
      createdAt: DateTime(2026, 5, 1),
    );

final _holiday = HolidayModel(
  date: DateTime(2026, 5, 5),
  name: '어린이날',
);

void main() {
  late CalendarRepositoryImpl repository;
  late MockCalendarRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeEventModel());
  });

  setUp(() {
    mockDataSource = MockCalendarRemoteDataSource();
    repository = CalendarRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getCalendarByMonth', () {
    test('events와 holidays를 병렬로 조회하고 CalendarData를 반환한다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => [_dummyModel()]);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => [_holiday]);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.events.length, 1);
      expect(result.events.first.title, '테스트');
      expect(result.habits, isEmpty);
      expect(result.ranges, isEmpty);
      expect(result.holidays.length, 1);
      expect(result.holidays.first.name, '어린이날');
      verify(() => mockDataSource.getEventsByDateRange(start, end)).called(1);
      verify(() => mockDataSource.getHolidaysByRange(start, end)).called(1);
    });

    test('공휴일 없는 달은 holidays가 빈 리스트다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => []);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => []);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.holidays, isEmpty);
    });
  });

  group('getCalendarByWeek', () {
    test('주 범위로 events와 holidays를 조회한다', () async {
      final weekStart = DateTime(2026, 5, 4);
      final weekEnd = weekStart
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      when(() => mockDataSource.getEventsByDateRange(weekStart, weekEnd))
          .thenAnswer((_) async => [_dummyModel()]);
      when(() => mockDataSource.getHolidaysByRange(weekStart, weekEnd))
          .thenAnswer((_) async => [_holiday]);

      final result = await repository.getCalendarByWeek(weekStart);

      expect(result.events.length, 1);
      expect(result.holidays.length, 1);
      expect(result.holidays.first.date, DateTime(2026, 5, 5));
    });
  });

  group('getCalendarByMonth — eventType 필터', () {
    test('habit 이벤트는 habits 리스트로, range는 ranges로 분리된다', () async {
      final habitModel = EventModel(
        id: 'habit-1',
        userId: 'user-1',
        title: '매일 운동',
        startAt: DateTime(2026, 5, 7, 7),
        endAt: DateTime(2026, 5, 7, 8),
        color: '#00FF00',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
        eventType: EventType.habit,
        recurrenceType: RecurrenceType.daily,
      );
      final rangeModel = EventModel(
        id: 'range-1',
        userId: 'user-1',
        title: '여름 방학',
        startAt: DateTime(2026, 5, 10),
        endAt: DateTime(2026, 5, 20),
        color: '#FF9900',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
        eventType: EventType.range,
      );
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => [_dummyModel(), habitModel, rangeModel]);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => []);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.events.length, 1);
      expect(result.events.first.id, 'event-1');
      expect(result.habits.length, 1);
      expect(result.habits.first.id, 'habit-1');
      expect(result.ranges.length, 1);
      expect(result.ranges.first.id, 'range-1');
    });
  });

  group('createEvent', () {
    test('DataSource.createEvent을 호출하고 EventEntity를 반환한다', () async {
      final model = _dummyModel();
      when(() => mockDataSource.createEvent(any()))
          .thenAnswer((_) async => model);

      final result = await repository.createEvent(model);

      expect(result.id, 'event-1');
      verify(() => mockDataSource.createEvent(any())).called(1);
    });
  });

  group('updateEvent', () {
    test('DataSource.updateEvent을 호출하고 EventEntity를 반환한다', () async {
      final model = _dummyModel();
      when(() => mockDataSource.updateEvent(any()))
          .thenAnswer((_) async => model);

      final result = await repository.updateEvent(model);

      expect(result.title, '테스트');
      verify(() => mockDataSource.updateEvent(any())).called(1);
    });
  });

  group('deleteEvent', () {
    test('DataSource.deleteEvent을 올바른 ID로 1회 호출한다', () async {
      when(() => mockDataSource.deleteEvent('event-1'))
          .thenAnswer((_) async {});

      await repository.deleteEvent('event-1');

      verify(() => mockDataSource.deleteEvent('event-1')).called(1);
    });
  });

  group('completeEvent', () {
    test('DataSource.completeEvent을 호출하고 status=done인 EventEntity를 반환한다',
        () async {
      final completed = EventModel(
        id: 'event-1',
        userId: 'user-1',
        title: '테스트',
        startAt: DateTime(2026, 5, 7, 10),
        endAt: DateTime(2026, 5, 7, 11),
        color: '#4A90D9',
        isDday: false,
        status: EventStatus.done,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
      );
      when(() => mockDataSource.completeEvent('event-1'))
          .thenAnswer((_) async => completed);

      final result = await repository.completeEvent('event-1');

      expect(result.status, EventStatus.done);
      verify(() => mockDataSource.completeEvent('event-1')).called(1);
    });
  });

  group('createHabitInstances', () {
    test('daily 3일치 habit → createEvent(parent) 1회 + createEvents(children) 1회',
        () async {
      final template = EventModel(
        id: '',
        userId: 'user-1',
        title: '운동',
        startAt: DateTime(2026, 5, 1, 7),
        endAt: DateTime(2026, 5, 1, 8),
        color: '#00FF00',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
        eventType: EventType.habit,
        recurrenceType: RecurrenceType.daily,
        recurrenceEndDate: DateTime(2026, 5, 3),
      );
      final parent = _dummyModel(id: 'parent-1');
      final children = [_dummyModel(id: 'child-1'), _dummyModel(id: 'child-2')];

      when(() => mockDataSource.createEvent(any()))
          .thenAnswer((_) async => parent);
      when(() => mockDataSource.createEvents(any()))
          .thenAnswer((_) async => children);

      final result = await repository.createHabitInstances(template);

      expect(result.length, 3);
      verify(() => mockDataSource.createEvent(any())).called(1);
      verify(() => mockDataSource.createEvents(any())).called(1);
    });

    test('recurrenceEndDate가 startAt과 같으면(단일 인스턴스) createEvents를 호출하지 않는다',
        () async {
      final template = EventModel(
        id: '',
        userId: 'user-1',
        title: '운동',
        startAt: DateTime(2026, 5, 1, 7),
        endAt: DateTime(2026, 5, 1, 8),
        color: '#00FF00',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
        eventType: EventType.habit,
        recurrenceType: RecurrenceType.daily,
        recurrenceEndDate: DateTime(2026, 5, 1),
      );
      final parent = _dummyModel(id: 'only-1');

      when(() => mockDataSource.createEvent(any()))
          .thenAnswer((_) async => parent);

      final result = await repository.createHabitInstances(template);

      expect(result.length, 1);
      verify(() => mockDataSource.createEvent(any())).called(1);
      verifyNever(() => mockDataSource.createEvents(any()));
    });
  });

  group('updateRecurringEvent — thisOnly', () {
    test('thisAndFuture=false이면 updateEvent 1회만 호출하고 deleteRecurringFrom 미호출',
        () async {
      final event = _dummyModel();
      when(() => mockDataSource.updateEvent(any()))
          .thenAnswer((_) async => event);

      final result = await repository.updateRecurringEvent(
        event: event,
        thisAndFuture: false,
      );

      expect(result.length, 1);
      verify(() => mockDataSource.updateEvent(any())).called(1);
      verifyNever(() => mockDataSource.deleteRecurringFrom(any(), any()));
    });
  });

  group('updateRecurringEvent — thisAndFuture', () {
    test('thisAndFuture=true이면 deleteRecurringFrom + createEvent + createEvents 순서로 호출',
        () async {
      final event = EventModel(
        id: 'event-2',
        userId: 'user-1',
        title: '운동',
        startAt: DateTime(2026, 5, 7, 7),
        endAt: DateTime(2026, 5, 7, 8),
        color: '#00FF00',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
        eventType: EventType.habit,
        recurrenceType: RecurrenceType.daily,
        recurrenceEndDate: DateTime(2026, 5, 8),
        parentEventId: 'parent-1',
      );
      when(() => mockDataSource.deleteRecurringFrom(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockDataSource.createEvent(any()))
          .thenAnswer((_) async => _dummyModel(id: 'new-parent'));
      when(() => mockDataSource.createEvents(any()))
          .thenAnswer((_) async => [_dummyModel(id: 'new-child')]);

      final result = await repository.updateRecurringEvent(
        event: event,
        thisAndFuture: true,
      );

      expect(result.isNotEmpty, true);
      verify(() => mockDataSource.deleteRecurringFrom('parent-1', event.startAt))
          .called(1);
      verify(() => mockDataSource.createEvent(any())).called(1);
    });
  });
}
