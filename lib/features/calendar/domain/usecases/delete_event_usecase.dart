import 'package:calddy/core/usecase/usecase.dart';
import '../repositories/calendar_repository.dart';

class DeleteEventParams {
  final String eventId;
  const DeleteEventParams({required this.eventId});
}

class DeleteEventUseCase implements UseCase<void, DeleteEventParams> {
  final CalendarRepository _repository;
  DeleteEventUseCase(this._repository);

  @override
  Future<void> call(DeleteEventParams params) =>
      _repository.deleteEvent(params.eventId);
}
