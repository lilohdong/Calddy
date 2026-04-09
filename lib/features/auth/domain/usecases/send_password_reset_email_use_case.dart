import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  SendPasswordResetEmailUseCase(this._repository);

  Future<void> call(String email) => _repository.sendPasswordResetEmail(email);
}
