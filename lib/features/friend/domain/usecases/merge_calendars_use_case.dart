import '../../../../core/usecase/usecase.dart';
import '../entities/free_slot_entity.dart';
import '../repositories/friend_repository.dart';

class MergeCalendarsParams {
  final List<String> friendIds;
  final DateTime from;
  final DateTime to;
  const MergeCalendarsParams({
    required this.friendIds,
    required this.from,
    required this.to,
  });
}

class MergeCalendarsUseCase
    implements UseCase<List<FreeSlotEntity>, MergeCalendarsParams> {
  final FriendRepository _repository;
  MergeCalendarsUseCase(this._repository);

  @override
  Future<List<FreeSlotEntity>> call(MergeCalendarsParams params) =>
      _repository.mergeCalendars(
        friendIds: params.friendIds,
        from: params.from,
        to: params.to,
      );
}
