import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  SignOutUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.signOut();
}
