import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  DeleteAccountUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.deleteAccount();
}
