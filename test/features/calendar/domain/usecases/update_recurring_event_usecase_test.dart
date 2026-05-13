import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:calddy/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calddy/features/calendar/domain/usecases/update_recurring_event_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

EventEntity _habitEvent({bool hasParent = false}) => EventEntity(
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
      parentEventId: hasParent ? 'parent-1' : null,
    );

void main() {
  late MockCalendarRepository repo;

  setUp(() => repo = MockCalendarRepository());

  group('UpdateRecurringEventUseCase — thisOnly', () {
    test('thisAndFuture=false이면 updateRecurringEvent(thisAndFuture: false) 호출', () async {
      final event = _habitEvent();
      when(() => repo.updateRecurringEvent(event: event, thisAndFuture: false))
          .thenAnswer((_) async => [event]);

      final useCase = UpdateRecurringEventUseCase(repo);
      final result = await useCase(
        UpdateRecurringParams(event: event, thisAndFuture: false),
      );

      expect(result.length, 1);
      verify(() => repo.updateRecurringEvent(event: event, thisAndFuture: false))
          .called(1);
    });
  });

  group('UpdateRecurringEventUseCase — thisAndFuture', () {
    test('thisAndFuture=true이면 updateRecurringEvent(thisAndFuture: true) 호출', () async {
      final event = _habitEvent(hasParent: true);
      final newInstances = [event.copyWith(id: 'new-1'), event.copyWith(id: 'new-2')];
      when(() => repo.updateRecurringEvent(event: event, thisAndFuture: true))
          .thenAnswer((_) async => newInstances);

      final useCase = UpdateRecurringEventUseCase(repo);
      final result = await useCase(
        UpdateRecurringParams(event: event, thisAndFuture: true),
      );

      expect(result.length, 2);
      verify(() => repo.updateRecurringEvent(event: event, thisAndFuture: true))
          .called(1);
    });
  });
}
