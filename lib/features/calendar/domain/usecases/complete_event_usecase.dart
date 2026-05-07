import 'package:calddy/core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class CompleteEventParams {
  final String eventId;
  const CompleteEventParams({required this.eventId});
}

class CompleteEventUseCase implements UseCase<EventEntity, CompleteEventParams> {
  final CalendarRepository _repository;
  CompleteEventUseCase(this._repository);

  @override
  Future<EventEntity> call(CompleteEventParams params) =>
      _repository.completeEvent(params.eventId);
}
