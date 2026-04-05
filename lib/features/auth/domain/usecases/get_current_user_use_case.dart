import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<AppUser?> call() => _repository.getCurrentUser();
}
