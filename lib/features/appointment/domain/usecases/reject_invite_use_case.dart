import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class RejectInviteParams {
  final String inviteId;
  const RejectInviteParams({required this.inviteId});
}

class RejectInviteUseCase implements UseCase<void, RejectInviteParams> {
  final AppointmentRepository _repository;
  RejectInviteUseCase(this._repository);

  @override
  Future<void> call(RejectInviteParams params) =>
      _repository.rejectInvite(params.inviteId);
}
