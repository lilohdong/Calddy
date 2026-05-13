import 'package:calddy/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_model.dart';
import '../models/invite_model.dart';
import 'appointment_remote_datasource.dart';

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final SupabaseClient _client;

  AppointmentRemoteDataSourceImpl(this._client);

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<AppointmentModel> createAppointment({
    required String eventId,
    required List<String> inviteeIds,
    String? suggestedPlace,
  }) async {
    _uid; // 세션 확인 (RPC 내부에서도 auth.uid() 사용)

    // 단일 트랜잭션 RPC: appointments INSERT + invites batch INSERT + events UPDATE
    final appointmentId = await _client.rpc(
      'create_appointment_with_invites',
      params: {
        'p_event_id': eventId,
        'p_invitee_ids': inviteeIds,
        'p_suggested_place': suggestedPlace,
      },
    ) as String;

    return getAppointment(appointmentId);
  }

  @override
  Future<AppointmentModel> getAppointment(String appointmentId) async {
    _uid; // 세션 확인
    final row = await _client
        .from(SupabaseConstants.appointments)
        .select('*, appointment_invites(*)')
        .eq('id', appointmentId)
        .single();
    return AppointmentModel.fromJson(row);
  }

  @override
  Future<List<InviteModel>> getMyInvites() async {
    final uid = _uid;
    final rows = await _client
        .from(SupabaseConstants.appointmentInvites)
        .select()
        .eq('invitee_id', uid)
        .eq('status', 'pending');
    return rows.map((r) => InviteModel.fromJson(r)).toList();
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    _uid;
    final rows = await _client
        .from(SupabaseConstants.appointmentInvites)
        .update({'status': 'accepted'})
        .eq('id', inviteId)
        .select();
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'invite not found or not authorized',
        code: 'PGRST116',
      );
    }
  }

  @override
  Future<void> rejectInvite(String inviteId) async {
    _uid;
    final rows = await _client
        .from(SupabaseConstants.appointmentInvites)
        .update({'status': 'rejected'})
        .eq('id', inviteId)
        .select();
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'invite not found or not authorized',
        code: 'PGRST116',
      );
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    _uid;
    // 해당 약속의 모든 invites를 cancelled로 일괄 업데이트
    // 트리거(trg_invite_cancelled)가 각 invitee의 복제 이벤트 삭제 처리
    await _client
        .from(SupabaseConstants.appointmentInvites)
        .update({'status': 'cancelled'})
        .eq('appointment_id', appointmentId);
  }

  @override
  Future<String?> getPlaceSuggestion(String appointmentId) async {
    _uid;
    final row = await _client
        .from(SupabaseConstants.appointments)
        .select('suggested_place')
        .eq('id', appointmentId)
        .single();
    return row['suggested_place'] as String?;
  }
}
