import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/datasources/appointment_remote_datasource_impl.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/invite_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/usecases/accept_invite_use_case.dart';
import '../../domain/usecases/cancel_appointment_use_case.dart';
import '../../domain/usecases/create_appointment_use_case.dart';
import '../../domain/usecases/get_appointment_use_case.dart';
import '../../domain/usecases/get_my_invites_use_case.dart';
import '../../domain/usecases/get_place_suggestion_use_case.dart';
import '../../domain/usecases/reject_invite_use_case.dart';
import '../../domain/usecases/request_place_suggestion_use_case.dart';
import '../../../../core/usecase/usecase.dart';

// 1. DataSource
final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) =>
        AppointmentRemoteDataSourceImpl(Supabase.instance.client));

// 2. Repository
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) =>
    AppointmentRepositoryImpl(
      remoteDataSource: ref.watch(appointmentRemoteDataSourceProvider),
    ));

// 3. UseCases
final createAppointmentUseCaseProvider = Provider((ref) =>
    CreateAppointmentUseCase(ref.watch(appointmentRepositoryProvider)));

final getAppointmentUseCaseProvider = Provider((ref) =>
    GetAppointmentUseCase(ref.watch(appointmentRepositoryProvider)));

final getMyInvitesUseCaseProvider = Provider((ref) =>
    GetMyInvitesUseCase(ref.watch(appointmentRepositoryProvider)));

final acceptInviteUseCaseProvider = Provider((ref) =>
    AcceptInviteUseCase(ref.watch(appointmentRepositoryProvider)));

final rejectInviteUseCaseProvider = Provider((ref) =>
    RejectInviteUseCase(ref.watch(appointmentRepositoryProvider)));

final cancelAppointmentUseCaseProvider = Provider((ref) =>
    CancelAppointmentUseCase(ref.watch(appointmentRepositoryProvider)));

final getPlaceSuggestionUseCaseProvider = Provider((ref) =>
    GetPlaceSuggestionUseCase(ref.watch(appointmentRepositoryProvider)));

final requestPlaceSuggestionUseCaseProvider = Provider((ref) =>
    RequestPlaceSuggestionUseCase(ref.watch(appointmentRepositoryProvider)));

// 4. 상태 Providers (UI가 watch)

/// 약속 상세 — appointmentId별로 autoDispose
final appointmentDetailProvider = FutureProvider.autoDispose
    .family<AppointmentEntity, String>((ref, appointmentId) {
  final useCase = ref.watch(getAppointmentUseCaseProvider);
  return useCase(GetAppointmentParams(appointmentId: appointmentId));
});

/// 현재 유저에게 온 pending 초대 목록
final myInvitesProvider =
    FutureProvider.autoDispose<List<InviteEntity>>((ref) {
  final useCase = ref.watch(getMyInvitesUseCaseProvider);
  return useCase(const NoParams());
});
