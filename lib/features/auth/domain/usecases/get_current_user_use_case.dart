import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  @override
  Future<UserEntity?> call(NoParams params) => _repository.getCurrentUser();
}
