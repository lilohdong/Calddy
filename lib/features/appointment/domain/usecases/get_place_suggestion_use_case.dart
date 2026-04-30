import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class GetPlaceSuggestionParams {
  final String appointmentId;
  const GetPlaceSuggestionParams({required this.appointmentId});
}

class GetPlaceSuggestionUseCase
    implements UseCase<String?, GetPlaceSuggestionParams> {
  final AppointmentRepository _repository;
  GetPlaceSuggestionUseCase(this._repository);

  @override
  Future<String?> call(GetPlaceSuggestionParams params) =>
      _repository.getPlaceSuggestion(params.appointmentId);
}
