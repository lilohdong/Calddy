import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendOtpParams {
  final String email;
  const SendOtpParams({required this.email});
}

class SendOtpUseCase implements UseCase<void, SendOtpParams> {
  final AuthRepository _repository;
  const SendOtpUseCase(this._repository);

  @override
  Future<void> call(SendOtpParams params) =>
      _repository.sendOtp(params.email);
}
