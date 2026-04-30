import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  SignInWithGoogleUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.signInWithGoogle();
}
