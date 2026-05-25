import '../../../../core/usecase/usecase.dart';
import '../entities/friend_entity.dart';
import '../repositories/friend_repository.dart';

class GetFriendsParams {
  final FriendSortType sortType;
  const GetFriendsParams({this.sortType = FriendSortType.alphabetical});
}

class GetFriendsUseCase implements UseCase<List<FriendEntity>, GetFriendsParams> {
  final FriendRepository _repository;
  GetFriendsUseCase(this._repository);

  @override
  Future<List<FriendEntity>> call(GetFriendsParams params) =>
      _repository.getFriends(params.sortType);
}
