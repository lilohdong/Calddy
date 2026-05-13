import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/invite_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource _dataSource;

  AppointmentRepositoryImpl(
      {required AppointmentRemoteDataSource remoteDataSource})
      : _dataSource = remoteDataSource;

  @override
  Future<AppointmentEntity> createAppointment({
    required String eventId,
    required List<String> inviteeIds,
    String? suggestedPlace,
  }) =>
      _guard(() => _dataSource.createAppointment(
            eventId: eventId,
            inviteeIds: inviteeIds,
            suggestedPlace: suggestedPlace,
          ));

  @override
  Future<AppointmentEntity> getAppointment(String appointmentId) =>
      _guard(() => _dataSource.getAppointment(appointmentId));

  @override
  Future<List<InviteEntity>> getMyInvites() =>
      _guard(() => _dataSource.getMyInvites());

  @override
  Future<void> acceptInvite(String inviteId) =>
      _guard(() => _dataSource.acceptInvite(inviteId));

  @override
  Future<void> rejectInvite(String inviteId) =>
      _guard(() => _dataSource.rejectInvite(inviteId));

  @override
  Future<void> cancelAppointment(String appointmentId) =>
      _guard(() => _dataSource.cancelAppointment(appointmentId));

  @override
  Future<String?> getPlaceSuggestion(String appointmentId) =>
      _guard(() => _dataSource.getPlaceSuggestion(appointmentId));

  // ── Private helpers ────────────────────────────────────────────────────

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AuthException {
      throw const AppointmentSessionExpiredFailure();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const AppointmentNotFoundFailure();
      throw AppointmentDatabaseFailure(e.message);
    } catch (_) {
      throw const AppointmentUnknownFailure();
    }
  }
}
