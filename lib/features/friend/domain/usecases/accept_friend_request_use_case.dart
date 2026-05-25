import '../../../../core/usecase/usecase.dart';
import '../repositories/friend_repository.dart';

class AcceptFriendRequestParams {
  final String requestId;
  const AcceptFriendRequestParams({required this.requestId});
}

class AcceptFriendRequestUseCase
    implements UseCase<void, AcceptFriendRequestParams> {
  final FriendRepository _repository;
  AcceptFriendRequestUseCase(this._repository);

  @override
  Future<void> call(AcceptFriendRequestParams params) =>
      _repository.acceptFriendRequest(params.requestId);
}
