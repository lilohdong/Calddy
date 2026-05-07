import 'package:calddy/core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class UpdateEventParams {
  final EventEntity event;
  const UpdateEventParams({required this.event});
}

class UpdateEventUseCase implements UseCase<EventEntity, UpdateEventParams> {
  final CalendarRepository _repository;
  UpdateEventUseCase(this._repository);

  @override
  Future<EventEntity> call(UpdateEventParams params) =>
      _repository.updateEvent(params.event);
}
