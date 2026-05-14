import '../../../../core/usecase/usecase.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentParams {
  final String appointmentId;
  const GetAppointmentParams({required this.appointmentId});
}

class GetAppointmentUseCase
    implements UseCase<AppointmentEntity, GetAppointmentParams> {
  final AppointmentRepository _repository;
  GetAppointmentUseCase(this._repository);

  @override
  Future<AppointmentEntity> call(GetAppointmentParams params) =>
      _repository.getAppointment(params.appointmentId);
}
