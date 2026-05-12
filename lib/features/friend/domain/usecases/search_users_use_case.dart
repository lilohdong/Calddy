import '../../../../core/usecase/usecase.dart';
import '../entities/searched_user_entity.dart';
import '../repositories/friend_repository.dart';

class SearchUsersParams {
  final String query;
  const SearchUsersParams({required this.query});
}

class SearchUsersUseCase
    implements UseCase<List<SearchedUserEntity>, SearchUsersParams> {
  final FriendRepository _repository;
  SearchUsersUseCase(this._repository);

  @override
  Future<List<SearchedUserEntity>> call(SearchUsersParams params) =>
      _repository.searchUsers(params.query);
}
