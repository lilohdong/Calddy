import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  Future<AppUser?> call({required String email, required String password}) =>
      _repository.signInWithEmail(email: email, password: password);
}
