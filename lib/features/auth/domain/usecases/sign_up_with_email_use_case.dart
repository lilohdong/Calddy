import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailParams {
  final String email;
  final String password;
  const SignUpWithEmailParams({required this.email, required this.password});
}

class SignUpWithEmailUseCase
    implements UseCase<UserEntity?, SignUpWithEmailParams> {
  final AuthRepository _repository;
  SignUpWithEmailUseCase(this._repository);

  @override
  Future<UserEntity?> call(SignUpWithEmailParams params) =>
      _repository.signUpWithEmail(
        email: params.email,
        password: params.password,
      );
}
