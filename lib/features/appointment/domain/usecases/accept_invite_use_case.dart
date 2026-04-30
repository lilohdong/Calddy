import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class AcceptInviteParams {
  final String inviteId;
  const AcceptInviteParams({required this.inviteId});
}

class AcceptInviteUseCase implements UseCase<void, AcceptInviteParams> {
  final AppointmentRepository _repository;
  AcceptInviteUseCase(this._repository);

  @override
  Future<void> call(AcceptInviteParams params) =>
      _repository.acceptInvite(params.inviteId);
}
