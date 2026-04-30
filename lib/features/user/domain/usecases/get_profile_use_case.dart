import '../../../../core/usecase/usecase.dart';
import '../entities/profile_entity.dart';
import '../repositories/user_repository.dart';

class GetProfileParams {
  final String userId;
  const GetProfileParams({required this.userId});
}

class GetProfileUseCase implements UseCase<ProfileEntity, GetProfileParams> {
  final UserRepository _repository;
  GetProfileUseCase(this._repository);

  @override
  Future<ProfileEntity> call(GetProfileParams params) =>
      _repository.getProfile(params.userId);
}
