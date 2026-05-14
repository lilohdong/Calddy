import '../../../../core/usecase/usecase.dart';
import '../entities/invite_entity.dart';
import '../repositories/appointment_repository.dart';

class GetMyInvitesUseCase implements UseCase<List<InviteEntity>, NoParams> {
  final AppointmentRepository _repository;
  GetMyInvitesUseCase(this._repository);

  @override
  Future<List<InviteEntity>> call(NoParams params) =>
      _repository.getMyInvites();
}
