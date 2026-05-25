import '../../../../core/usecase/usecase.dart';
import '../repositories/friend_repository.dart';

class RejectFriendRequestParams {
  final String requestId;
  const RejectFriendRequestParams({required this.requestId});
}

class RejectFriendRequestUseCase
    implements UseCase<void, RejectFriendRequestParams> {
  final FriendRepository _repository;
  RejectFriendRequestUseCase(this._repository);

  @override
  Future<void> call(RejectFriendRequestParams params) =>
      _repository.rejectFriendRequest(params.requestId);
}
