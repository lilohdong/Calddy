import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CompleteOnboardingParams {
  final String nickname;
  final DateTime termsAgreedAt;
  final String termsVersion;

  const CompleteOnboardingParams({
    required this.nickname,
    required this.termsAgreedAt,
    required this.termsVersion,
  });
}

class CompleteOnboardingUseCase
    implements UseCase<void, CompleteOnboardingParams> {
  final AuthRepository _repository;
  CompleteOnboardingUseCase(this._repository);

  @override
  Future<void> call(CompleteOnboardingParams params) =>
      _repository.completeOnboarding(
        nickname: params.nickname,
        termsAgreedAt: params.termsAgreedAt,
        termsVersion: params.termsVersion,
      );
}
