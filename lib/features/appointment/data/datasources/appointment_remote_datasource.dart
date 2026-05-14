import '../models/appointment_model.dart';
import '../models/invite_model.dart';

abstract interface class AppointmentRemoteDataSource {
  Future<AppointmentModel> createAppointment({
    required String eventId,
    required List<String> inviteeIds,
    String? suggestedPlace,
  });

  Future<AppointmentModel> getAppointment(String appointmentId);

  Future<List<InviteModel>> getMyInvites();

  Future<void> acceptInvite(String inviteId);

  Future<void> rejectInvite(String inviteId);

  /// 약속에 속한 모든 invites를 cancelled로 일괄 업데이트
  Future<void> cancelAppointment(String appointmentId);

  Future<String?> getPlaceSuggestion(String appointmentId);
}
