import '../../../../core/usecase/usecase.dart';
import '../repositories/friend_repository.dart';

class SendFriendRequestParams {
  final String addresseeId;
  const SendFriendRequestParams({required this.addresseeId});
}

class SendFriendRequestUseCase
    implements UseCase<void, SendFriendRequestParams> {
  final FriendRepository _repository;
  SendFriendRequestUseCase(this._repository);

  @override
  Future<void> call(SendFriendRequestParams params) =>
      _repository.sendFriendRequest(params.addresseeId);
}
