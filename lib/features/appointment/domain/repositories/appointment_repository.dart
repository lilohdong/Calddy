import '../entities/appointment_entity.dart';
import '../entities/invite_entity.dart';

abstract interface class AppointmentRepository {
  Future<AppointmentEntity> createAppointment({
    required String eventId,
    required List<String> inviteeIds,
    String? suggestedPlace,
  });

  Future<AppointmentEntity> getAppointment(String appointmentId);

  /// 현재 로그인 유저에게 온 초대 목록 (pending 상태)
  Future<List<InviteEntity>> getMyInvites();

  Future<void> acceptInvite(String inviteId);
  Future<void> rejectInvite(String inviteId);

  /// creator가 약속 전체 취소 — 트리거가 invitee 복제 이벤트 삭제 처리
  Future<void> cancelAppointment(String appointmentId);

  Future<String?> getPlaceSuggestion(String appointmentId);

  /// 장소 추천 요청: Edge Function 호출 후 appointments.suggested_place 저장
  Future<String?> requestPlaceSuggestion(String appointmentId);
}
