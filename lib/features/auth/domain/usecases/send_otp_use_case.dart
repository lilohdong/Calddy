import '../../../../core/usecase/usecase.dart';

class SendOtpParams {
  final String email;
  const SendOtpParams({required this.email});
}

/// OTP 전송 UseCase — AuthRepository.sendOtp 추가 시 구현 예정
class SendOtpUseCase implements UseCase<void, SendOtpParams> {
  const SendOtpUseCase();

  @override
  Future<void> call(SendOtpParams params) =>
      throw UnimplementedError('SendOtpUseCase: AuthRepository.sendOtp 구현 필요');
}
