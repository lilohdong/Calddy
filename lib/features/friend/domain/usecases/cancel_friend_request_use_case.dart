import '../../../../core/usecase/usecase.dart';
import '../repositories/friend_repository.dart';

class CancelFriendRequestUseCase
    implements UseCase<void, CancelFriendRequestParams> {
  final FriendRepository _repository;

  CancelFriendRequestUseCase(this._repository);

  @override
  Future<void> call(CancelFriendRequestParams params) {
    return _repository.cancelFriendRequest(params.requestId);
  }
}

class CancelFriendRequestParams {
  final String requestId;
  const CancelFriendRequestParams({required this.requestId});
}
