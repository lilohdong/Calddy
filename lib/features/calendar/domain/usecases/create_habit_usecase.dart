import 'package:calddy/core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class CreateHabitParams {
  final EventEntity template;
  const CreateHabitParams({required this.template});
}

class CreateHabitUseCase
    implements UseCase<List<EventEntity>, CreateHabitParams> {
  final CalendarRepository _repository;
  CreateHabitUseCase(this._repository);

  @override
  Future<List<EventEntity>> call(CreateHabitParams params) =>
      _repository.createHabitInstances(params.template);
}
