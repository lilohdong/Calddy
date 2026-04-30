import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class DeleteAllNotificationsUseCase implements UseCase<void, NoParams> {
  final NotificationRepository _repository;
  DeleteAllNotificationsUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.deleteAllNotifications();
}
