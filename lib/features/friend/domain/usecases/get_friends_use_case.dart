import '../../../../core/usecase/usecase.dart';
import '../entities/friend_entity.dart';
import '../repositories/friend_repository.dart';

class GetFriendsUseCase implements UseCase<List<FriendEntity>, NoParams> {
  final FriendRepository _repository;
  GetFriendsUseCase(this._repository);

  @override
  Future<List<FriendEntity>> call(NoParams params) =>
      _repository.getFriends();
}
