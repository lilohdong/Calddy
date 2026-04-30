import '../../../../core/usecase/usecase.dart';
import '../repositories/user_repository.dart';

class WithdrawUseCase implements UseCase<void, NoParams> {
  final UserRepository _repository;
  WithdrawUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.withdraw();
}
