import 'package:calddy/core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class UpdateRecurringParams {
  final EventEntity event;
  final bool thisAndFuture;
  const UpdateRecurringParams({required this.event, required this.thisAndFuture});
}

class UpdateRecurringEventUseCase
    implements UseCase<List<EventEntity>, UpdateRecurringParams> {
  final CalendarRepository _repository;
  UpdateRecurringEventUseCase(this._repository);

  @override
  Future<List<EventEntity>> call(UpdateRecurringParams params) =>
      _repository.updateRecurringEvent(
        event: params.event,
        thisAndFuture: params.thisAndFuture,
      );
}
