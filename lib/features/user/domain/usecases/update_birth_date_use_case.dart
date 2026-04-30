import '../../../../core/usecase/usecase.dart';
import '../repositories/user_repository.dart';

class UpdateBirthDateParams {
  final DateTime birthDate;
  const UpdateBirthDateParams({required this.birthDate});
}

class UpdateBirthDateUseCase implements UseCase<void, UpdateBirthDateParams> {
  final UserRepository _repository;
  UpdateBirthDateUseCase(this._repository);

  @override
  Future<void> call(UpdateBirthDateParams params) =>
      _repository.updateBirthDate(params.birthDate);
}
