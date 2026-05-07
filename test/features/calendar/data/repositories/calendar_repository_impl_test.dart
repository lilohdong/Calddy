import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calddy/features/calendar/data/models/event_model.dart';
import 'package:calddy/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
    test('5월 범위로 getEventsByDateRange를 호출하고 CalendarData를 반환한다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => [_dummyModel()]);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.events.length, 1);
      expect(result.events.first.title, '테스트');
      expect(result.habits, isEmpty);
      expect(result.ranges, isEmpty);
      verify(() => mockDataSource.getEventsByDateRange(start, end)).called(1);
    });
  });

  group('getCalendarByWeek', () {
    test('주 시작~종료 범위로 getEventsByDateRange를 호출한다', () async {
      final weekStart = DateTime(2026, 5, 4);
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      when(() => mockDataSource.getEventsByDateRange(weekStart, weekEnd))
          .thenAnswer((_) async => []);

      final result = await repository.getCalendarByWeek(weekStart);

      expect(result.events, isEmpty);
      verify(() => mockDataSource.getEventsByDateRange(weekStart, weekEnd))
          .called(1);
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
    test('DataSource.deleteEvent을 1회 호출한다', () async {
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
}
