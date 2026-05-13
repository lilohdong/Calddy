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
    final uid = _uid;

    // 1. appointments INSERT
    final apptRow = await _client
        .from(SupabaseConstants.appointments)
        .insert({
          'event_id': eventId,
          'creator_id': uid,
          'suggested_place': suggestedPlace,
        })
        .select()
        .single();
    final appointmentId = apptRow['id'] as String;

    // 2. invites batch INSERT
    final inviteRows = await _client
        .from(SupabaseConstants.appointmentInvites)
        .insert(
          inviteeIds
              .map((id) => {
                    'appointment_id': appointmentId,
                    'invitee_id': id,
                    'status': 'pending',
                  })
              .toList(),
        )
        .select();

    // 3. creator 이벤트에 appointment_id 연결
    await _client
        .from(SupabaseConstants.events)
        .update({'appointment_id': appointmentId})
        .eq('id', eventId)
        .eq('user_id', uid);

    final invites =
        inviteRows.map((r) => InviteModel.fromJson(r)).toList();
    return AppointmentModel(
      id: appointmentId,
      eventId: apptRow['event_id'] as String,
      creatorId: apptRow['creator_id'] as String,
      suggestedPlace: apptRow['suggested_place'] as String?,
      invites: invites,
      createdAt: DateTime.parse(apptRow['created_at'] as String),
    );
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
        .select('*, appointments(*)')
        .eq('invitee_id', uid)
        .eq('status', 'pending');
    return rows.map((r) => InviteModel.fromJson(r)).toList();
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    _uid;
    await _client
        .from(SupabaseConstants.appointmentInvites)
        .update({'status': 'accepted'})
        .eq('id', inviteId);
  }

  @override
  Future<void> rejectInvite(String inviteId) async {
    _uid;
    await _client
        .from(SupabaseConstants.appointmentInvites)
        .update({'status': 'rejected'})
        .eq('id', inviteId);
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
