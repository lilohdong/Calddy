import '../../../../core/usecase/usecase.dart';
import '../entities/friend_entity.dart';
import '../repositories/friend_repository.dart';

class GetIncomingRequestsUseCase
    implements UseCase<List<FriendRequestEntity>, NoParams> {
  final FriendRepository _repository;
  GetIncomingRequestsUseCase(this._repository);

  @override
  Future<List<FriendRequestEntity>> call(NoParams params) =>
      _repository.getIncomingRequests();
}
