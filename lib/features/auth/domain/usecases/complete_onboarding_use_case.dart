import '../repositories/auth_repository.dart';

class CompleteOnboardingUseCase {
  final AuthRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  Future<void> call({required String nickname}) =>
      _repository.completeOnboarding(nickname: nickname);
}
