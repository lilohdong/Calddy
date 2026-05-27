import '../../../../core/usecase/usecase.dart';
import '../repositories/user_repository.dart';

class UpdateAvatarParams {
  final String filePath;
  const UpdateAvatarParams({required this.filePath});
}

class UpdateAvatarUseCase implements UseCase<String?, UpdateAvatarParams> {
  final UserRepository _repository;
  UpdateAvatarUseCase(this._repository);

  @override
  Future<String?> call(UpdateAvatarParams params) =>
      _repository.updateAvatar(params.filePath);
}
