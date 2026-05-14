import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams {
  final String email;
  final String token;
  const VerifyOtpParams({required this.email, required this.token});
}

class VerifyOtpUseCase implements UseCase<void, VerifyOtpParams> {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  @override
  Future<void> call(VerifyOtpParams params) =>
      _repository.verifyOtp(email: params.email, token: params.token);
}
