import '../../../../core/usecase/usecase.dart';
import '../entities/free_slot_entity.dart';
import '../repositories/friend_repository.dart';

class SuggestAppointmentParams {
  final String friendId;
  const SuggestAppointmentParams({required this.friendId});
}

/// 오늘 기준 가장 가까운 빈 시간대 1개 반환. 없으면 null.
class SuggestAppointmentUseCase
    implements UseCase<FreeSlotEntity?, SuggestAppointmentParams> {
  final FriendRepository _repository;
  SuggestAppointmentUseCase(this._repository);

  @override
  Future<FreeSlotEntity?> call(SuggestAppointmentParams params) =>
      _repository.suggestAppointment(params.friendId);
}
