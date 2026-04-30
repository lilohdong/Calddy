import '../../../../core/usecase/usecase.dart';

class VerifyOtpParams {
  final String email;
  final String token;
  const VerifyOtpParams({required this.email, required this.token});
}

/// OTP 검증 UseCase — AuthRepository에 verifyOtp 추가 시 구현 예정
class VerifyOtpUseCase implements UseCase<void, VerifyOtpParams> {
  const VerifyOtpUseCase();

  @override
  Future<void> call(VerifyOtpParams params) =>
      throw UnimplementedError('VerifyOtpUseCase: AuthRepository.verifyOtp 구현 필요');
}
