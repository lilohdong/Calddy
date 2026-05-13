import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:calddy/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calddy/features/calendar/domain/usecases/create_habit_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

EventEntity _habitTemplate() => EventEntity(
      id: '',
      userId: 'user-1',
      title: '매일 운동',
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

void main() {
  late MockCalendarRepository repo;

  setUp(() => repo = MockCalendarRepository());

  group('CreateHabitUseCase', () {
    test('repository.createHabitInstances를 1회 호출하고 인스턴스 리스트를 반환한다', () async {
      final template = _habitTemplate();
      final instances = [
        template.copyWith(id: 'h-1', startAt: DateTime(2026, 5, 1, 7)),
        template.copyWith(id: 'h-2', startAt: DateTime(2026, 5, 2, 7)),
        template.copyWith(id: 'h-3', startAt: DateTime(2026, 5, 3, 7)),
      ];
      when(() => repo.createHabitInstances(template))
          .thenAnswer((_) async => instances);

      final useCase = CreateHabitUseCase(repo);
      final result = await useCase(CreateHabitParams(template: template));

      expect(result.length, 3);
      expect(result.first.eventType, EventType.habit);
      verify(() => repo.createHabitInstances(template)).called(1);
    });
  });
}
