import '../../../../core/usecase/usecase.dart';
import '../repositories/user_repository.dart';

class UpdateNicknameParams {
  final String nickname;
  const UpdateNicknameParams({required this.nickname});
}

class UpdateNicknameUseCase implements UseCase<void, UpdateNicknameParams> {
  final UserRepository _repository;
  UpdateNicknameUseCase(this._repository);

  @override
  Future<void> call(UpdateNicknameParams params) =>
      _repository.updateNickname(params.nickname);
}
