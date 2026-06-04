import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  final NotificationRepository _repository;
  MarkAllNotificationsReadUseCase(this._repository);

  @override
  Future<void> call(NoParams params) => _repository.markAllAsRead();
}
