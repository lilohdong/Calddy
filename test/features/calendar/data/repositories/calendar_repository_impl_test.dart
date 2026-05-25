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

  group('getHolidaysByRange', () {
    test('DataSource에서 반환된 HolidayModel을 HolidayEntity로 변환해 반환한다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => [_holiday]);

      final result = await repository.getHolidaysByRange(start, end);

      expect(result.length, 1);
      expect(result.first.date, DateTime(2026, 5, 5));
      expect(result.first.name, '어린이날');
      verify(() => mockDataSource.getHolidaysByRange(start, end)).called(1);
    });

    test('DataSource가 PostgrestException을 던지면 CalendarDatabaseFailure로 변환한다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenThrow(PostgrestException(message: 'db error'));

      expect(
        () => repository.getHolidaysByRange(start, end),
        throwsA(isA<CalendarDatabaseFailure>()),
      );
    });
  });
}
