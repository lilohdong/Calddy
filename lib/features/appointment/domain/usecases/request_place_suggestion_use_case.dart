import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class RequestPlaceSuggestionParams {
  final String appointmentId;
  const RequestPlaceSuggestionParams({required this.appointmentId});
}

class RequestPlaceSuggestionUseCase
    implements UseCase<String?, RequestPlaceSuggestionParams> {
  final AppointmentRepository _repository;
  RequestPlaceSuggestionUseCase(this._repository);

  @override
  Future<String?> call(RequestPlaceSuggestionParams params) =>
      _repository.requestPlaceSuggestion(params.appointmentId);
}
