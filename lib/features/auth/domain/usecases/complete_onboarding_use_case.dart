import '../repositories/auth_repository.dart';

class CompleteOnboardingUseCase {
  final AuthRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  Future<void> call({required String userId, required String nickname}) =>
      _repository.completeOnboarding(userId: userId, nickname: nickname);
}
