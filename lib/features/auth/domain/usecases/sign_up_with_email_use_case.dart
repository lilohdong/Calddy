import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  SignUpWithEmailUseCase(this._repository);

  Future<AppUser?> call({required String email, required String password}) =>
      _repository.signUpWithEmail(email: email, password: password);
}
