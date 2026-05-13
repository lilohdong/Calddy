import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class CancelAppointmentParams {
  final String appointmentId;
  const CancelAppointmentParams({required this.appointmentId});
}

class CancelAppointmentUseCase
    implements UseCase<void, CancelAppointmentParams> {
  final AppointmentRepository _repository;
  CancelAppointmentUseCase(this._repository);

  @override
  Future<void> call(CancelAppointmentParams params) =>
      _repository.cancelAppointment(params.appointmentId);
}
