import 'package:calddy/features/calendar/domain/entities/calendar_data.dart';
import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:calddy/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calddy/features/calendar/domain/usecases/complete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/create_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/delete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_month_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_week_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/update_event_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

EventEntity _dummyEvent({String id = 'event-1'}) => EventEntity(
      id: id,
      userId: 'user-1',
      title: '테스트 일정',
      startAt: DateTime(2026, 5, 7, 10),
      endAt: DateTime(2026, 5, 7, 11),
      color: '#4A90D9',
      isDday: false,
      status: EventStatus.pending,
      visibility: EventVisibility.public,
      createdAt: DateTime(2026, 5, 7),
    );

void main() {
  late MockCalendarRepository repo;

  setUp(() {
    repo = MockCalendarRepository();
  });

  group('GetCalendarByMonthUseCase', () {
    test('repository.getCalendarByMonth을 1회 호출하고 결과를 반환한다', () async {
      final expected = CalendarData(events: [_dummyEvent()]);
      when(() => repo.getCalendarByMonth(2026, 5))
          .thenAnswer((_) async => expected);

      final useCase = GetCalendarByMonthUseCase(repo);
      final result = await useCase(
        const GetCalendarByMonthParams(year: 2026, month: 5),
      );

      expect(result.events.length, 1);
      verify(() => repo.getCalendarByMonth(2026, 5)).called(1);
    });
  });

  group('GetCalendarByWeekUseCase', () {
    test('repository.getCalendarByWeek을 1회 호출하고 결과를 반환한다', () async {
      final weekStart = DateTime(2026, 5, 4);
      final expected = CalendarData(events: [_dummyEvent()]);
      when(() => repo.getCalendarByWeek(weekStart))
          .thenAnswer((_) async => expected);

      final useCase = GetCalendarByWeekUseCase(repo);
      final result = await useCase(GetCalendarByWeekParams(weekStart: weekStart));

      expect(result.events.length, 1);
      verify(() => repo.getCalendarByWeek(weekStart)).called(1);
    });
  });

  group('CreateEventUseCase', () {
    test('repository.createEvent을 1회 호출하고 생성된 EventEntity를 반환한다', () async {
      final event = _dummyEvent();
      when(() => repo.createEvent(event)).thenAnswer((_) async => event);

      final useCase = CreateEventUseCase(repo);
      final result = await useCase(CreateEventParams(event: event));

      expect(result.id, 'event-1');
      verify(() => repo.createEvent(event)).called(1);
    });
  });

  group('UpdateEventUseCase', () {
    test('repository.updateEvent을 1회 호출하고 수정된 EventEntity를 반환한다', () async {
      final event = _dummyEvent();
      when(() => repo.updateEvent(event)).thenAnswer((_) async => event);

      final useCase = UpdateEventUseCase(repo);
      final result = await useCase(UpdateEventParams(event: event));

      expect(result.title, '테스트 일정');
      verify(() => repo.updateEvent(event)).called(1);
    });
  });

  group('DeleteEventUseCase', () {
    test('repository.deleteEvent을 1회 호출한다', () async {
      when(() => repo.deleteEvent('event-1')).thenAnswer((_) async {});

      final useCase = DeleteEventUseCase(repo);
      await useCase(const DeleteEventParams(eventId: 'event-1'));

      verify(() => repo.deleteEvent('event-1')).called(1);
    });
  });

  group('CompleteEventUseCase', () {
    test('repository.completeEvent을 1회 호출하고 status=done인 EventEntity를 반환한다',
        () async {
      final completed = _dummyEvent().copyWith(status: EventStatus.done);
      when(() => repo.completeEvent('event-1'))
          .thenAnswer((_) async => completed);

      final useCase = CompleteEventUseCase(repo);
      final result = await useCase(const CompleteEventParams(eventId: 'event-1'));

      expect(result.status, EventStatus.done);
      verify(() => repo.completeEvent('event-1')).called(1);
    });
  });
}
