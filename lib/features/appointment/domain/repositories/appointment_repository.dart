import '../entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Future<AppointmentEntity> createAppointment({
    required String eventId,
    required List<String> inviteeIds,
    String? suggestedPlace,
  });

  Future<void> acceptInvite(String inviteId);
  Future<void> rejectInvite(String inviteId);
  Future<String?> getPlaceSuggestion(String appointmentId);
}
