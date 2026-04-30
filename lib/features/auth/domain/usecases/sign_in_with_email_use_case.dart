import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailParams {
  final String email;
  final String password;
  const SignInWithEmailParams({required this.email, required this.password});
}

class SignInWithEmailUseCase
    implements UseCase<UserEntity?, SignInWithEmailParams> {
  final AuthRepository _repository;
  SignInWithEmailUseCase(this._repository);

  @override
  Future<UserEntity?> call(SignInWithEmailParams params) =>
      _repository.signInWithEmail(
        email: params.email,
        password: params.password,
      );
}
