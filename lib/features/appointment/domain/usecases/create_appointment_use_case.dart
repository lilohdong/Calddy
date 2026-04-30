import '../../../../core/usecase/usecase.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class CreateAppointmentParams {
  final String eventId;
  final List<String> inviteeIds;
  final String? suggestedPlace;
  const CreateAppointmentParams({
    required this.eventId,
    required this.inviteeIds,
    this.suggestedPlace,
  });
}

class CreateAppointmentUseCase
    implements UseCase<AppointmentEntity, CreateAppointmentParams> {
  final AppointmentRepository _repository;
  CreateAppointmentUseCase(this._repository);

  @override
  Future<AppointmentEntity> call(CreateAppointmentParams params) =>
      _repository.createAppointment(
        eventId: params.eventId,
        inviteeIds: params.inviteeIds,
        suggestedPlace: params.suggestedPlace,
      );
}
