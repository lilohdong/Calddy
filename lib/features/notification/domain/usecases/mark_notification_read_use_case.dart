import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadParams {
  final String notificationId;
  const MarkNotificationReadParams({required this.notificationId});
}

class MarkNotificationReadUseCase
    implements UseCase<void, MarkNotificationReadParams> {
  final NotificationRepository _repository;
  MarkNotificationReadUseCase(this._repository);

  @override
  Future<void> call(MarkNotificationReadParams params) =>
      _repository.markAsRead(params.notificationId);
}
