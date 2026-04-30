import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class DeleteNotificationParams {
  final String notificationId;
  const DeleteNotificationParams({required this.notificationId});
}

class DeleteNotificationUseCase
    implements UseCase<void, DeleteNotificationParams> {
  final NotificationRepository _repository;
  DeleteNotificationUseCase(this._repository);

  @override
  Future<void> call(DeleteNotificationParams params) =>
      _repository.deleteNotification(params.notificationId);
}
