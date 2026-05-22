import '../../../../core/usecase/usecase.dart';
import '../entities/friend_calendar_event_entity.dart';
import '../repositories/friend_repository.dart';

class GetFriendCalendarParams {
  final String friendId;
  final DateTime from;
  final DateTime to;
  const GetFriendCalendarParams({
    required this.friendId,
    required this.from,
    required this.to,
  });
}

class GetFriendCalendarUseCase
    implements UseCase<List<FriendCalendarEventEntity>, GetFriendCalendarParams> {
  final FriendRepository _repository;
  GetFriendCalendarUseCase(this._repository);

  @override
  Future<List<FriendCalendarEventEntity>> call(GetFriendCalendarParams params) =>
      _repository.getFriendCalendar(
        friendId: params.friendId,
        from: params.from,
        to: params.to,
      );
}
