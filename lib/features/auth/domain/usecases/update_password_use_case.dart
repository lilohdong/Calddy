import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/password.dart';

class UpdatePasswordParams {
  final String newPassword;
  const UpdatePasswordParams({required this.newPassword});
}

class UpdatePasswordUseCase implements UseCase<void, UpdatePasswordParams> {
  final AuthRepository _repository;
  UpdatePasswordUseCase(this._repository);

  @override
  Future<void> call(UpdatePasswordParams params) {
    final error = Password.validate(params.newPassword);
    if (error != null) throw error;
    return _repository.updatePassword(params.newPassword);
  }
}
