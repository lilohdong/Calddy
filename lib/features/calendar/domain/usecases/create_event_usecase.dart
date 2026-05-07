import 'package:calddy/core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class CreateEventParams {
  final EventEntity event;
  const CreateEventParams({required this.event});
}

class CreateEventUseCase implements UseCase<EventEntity, CreateEventParams> {
  final CalendarRepository _repository;
  CreateEventUseCase(this._repository);

  @override
  Future<EventEntity> call(CreateEventParams params) =>
      _repository.createEvent(params.event);
}
