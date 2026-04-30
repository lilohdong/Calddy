import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetEmailParams {
  final String email;
  const SendPasswordResetEmailParams(this.email);
}

class SendPasswordResetEmailUseCase
    implements UseCase<void, SendPasswordResetEmailParams> {
  final AuthRepository _repository;
  SendPasswordResetEmailUseCase(this._repository);

  @override
  Future<void> call(SendPasswordResetEmailParams params) =>
      _repository.sendPasswordResetEmail(params.email);
}
