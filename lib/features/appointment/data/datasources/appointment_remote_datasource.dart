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

  /// 장소 추천 요청: calculate-midpoint → recommend-place 순서로 Edge Function 호출 후
  /// appointments.suggested_place에 결과 저장
  Future<String?> requestPlaceSuggestion(String appointmentId);
}
