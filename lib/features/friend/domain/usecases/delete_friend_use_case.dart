import '../../../../core/usecase/usecase.dart';
import '../repositories/friend_repository.dart';

class DeleteFriendParams {
  final String friendId;
  const DeleteFriendParams({required this.friendId});
}

class DeleteFriendUseCase implements UseCase<void, DeleteFriendParams> {
  final FriendRepository _repository;
  DeleteFriendUseCase(this._repository);

  @override
  Future<void> call(DeleteFriendParams params) =>
      _repository.deleteFriend(params.friendId);
}
