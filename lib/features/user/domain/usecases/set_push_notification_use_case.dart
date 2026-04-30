import '../../../../core/usecase/usecase.dart';
import '../repositories/user_repository.dart';

class SetPushNotificationParams {
  final bool enabled;
  final String? fcmToken;
  const SetPushNotificationParams({required this.enabled, this.fcmToken});
}

class SetPushNotificationUseCase
    implements UseCase<void, SetPushNotificationParams> {
  final UserRepository _repository;
  SetPushNotificationUseCase(this._repository);

  @override
  Future<void> call(SetPushNotificationParams params) =>
      _repository.setPushNotification(
        enabled: params.enabled,
        fcmToken: params.fcmToken,
      );
}
