import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase
    implements UseCase<List<NotificationEntity>, NoParams> {
  final NotificationRepository _repository;
  GetNotificationsUseCase(this._repository);

  @override
  Future<List<NotificationEntity>> call(NoParams params) =>
      _repository.getNotifications();
}
