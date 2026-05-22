import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/friend_remote_datasource.dart';
import '../../data/datasources/friend_remote_datasource_impl.dart';
import '../../data/repositories/friend_repository_impl.dart';
import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../domain/usecases/accept_friend_request_use_case.dart';
import '../../domain/usecases/cancel_friend_request_use_case.dart';
import '../../domain/usecases/delete_friend_use_case.dart';
import '../../domain/usecases/get_friend_calendar_use_case.dart';
import '../../domain/usecases/get_friends_use_case.dart';
import '../../domain/usecases/get_incoming_requests_use_case.dart';
import '../../domain/usecases/merge_calendars_use_case.dart';
import '../../domain/usecases/reject_friend_request_use_case.dart';
import '../../domain/usecases/suggest_appointment_use_case.dart';
import '../../domain/usecases/search_users_use_case.dart';
import '../../domain/usecases/send_friend_request_use_case.dart';

// ── DataSource ───────────────────────────────────────────────────────────────

final friendRemoteDataSourceProvider = Provider<FriendRemoteDataSource>((ref) {
  return FriendRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
  );
});

// ── Repository ───────────────────────────────────────────────────────────────

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepositoryImpl(
    remoteDataSource: ref.watch(friendRemoteDataSourceProvider),
  );
});

// ── UseCases ─────────────────────────────────────────────────────────────────

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>((ref) {
  return SearchUsersUseCase(ref.watch(friendRepositoryProvider));
});

final sendFriendRequestUseCaseProvider =
    Provider<SendFriendRequestUseCase>((ref) {
  return SendFriendRequestUseCase(ref.watch(friendRepositoryProvider));
});

final acceptFriendRequestUseCaseProvider =
    Provider<AcceptFriendRequestUseCase>((ref) {
  return AcceptFriendRequestUseCase(ref.watch(friendRepositoryProvider));
});

final cancelFriendRequestUseCaseProvider =
    Provider<CancelFriendRequestUseCase>((ref) {
  return CancelFriendRequestUseCase(ref.watch(friendRepositoryProvider));
});

final rejectFriendRequestUseCaseProvider =
    Provider<RejectFriendRequestUseCase>((ref) {
  return RejectFriendRequestUseCase(ref.watch(friendRepositoryProvider));
});

final getFriendsUseCaseProvider = Provider<GetFriendsUseCase>((ref) {
  return GetFriendsUseCase(ref.watch(friendRepositoryProvider));
});

final deleteFriendUseCaseProvider = Provider<DeleteFriendUseCase>((ref) {
  return DeleteFriendUseCase(ref.watch(friendRepositoryProvider));
});

final getIncomingRequestsUseCaseProvider =
    Provider<GetIncomingRequestsUseCase>((ref) {
  return GetIncomingRequestsUseCase(ref.watch(friendRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

/// 친구 목록 (가나다순, pull-to-refresh 시 invalidate)
final friendsProvider = FutureProvider<List<FriendEntity>>((ref) {
  return ref.watch(getFriendsUseCaseProvider).call(const NoParams());
});

/// 받은 친구 요청 목록 (pending)
final incomingRequestsProvider =
    FutureProvider<List<FriendRequestEntity>>((ref) {
  return ref.watch(getIncomingRequestsUseCaseProvider).call(const NoParams());
});

// ── P2 UseCase Providers ──────────────────────────────────────────────────────

final getFriendCalendarUseCaseProvider =
    Provider<GetFriendCalendarUseCase>((ref) {
  return GetFriendCalendarUseCase(ref.watch(friendRepositoryProvider));
});

final mergeCalendarsUseCaseProvider = Provider<MergeCalendarsUseCase>((ref) {
  return MergeCalendarsUseCase(ref.watch(friendRepositoryProvider));
});

final suggestAppointmentUseCaseProvider = Provider<SuggestAppointmentUseCase>((ref) {
  return SuggestAppointmentUseCase(ref.watch(friendRepositoryProvider));
});

// ── P2 State Providers (family) ───────────────────────────────────────────────

/// 친구 이번 달 공개 일정
final friendCalendarProvider = FutureProvider.autoDispose
    .family<List<FriendCalendarEventEntity>, String>((ref, friendId) {
  final now = DateTime.now();
  return ref.watch(getFriendCalendarUseCaseProvider).call(
        GetFriendCalendarParams(
          friendId: friendId,
          from: DateTime(now.year, now.month, 1),
          to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        ),
      );
});

/// 나와 친구의 공통 빈 시간 (오늘~+30일)
final mergeCalendarProvider = FutureProvider.autoDispose
    .family<List<FreeSlotEntity>, String>((ref, friendId) {
  final now = DateTime.now();
  return ref.watch(mergeCalendarsUseCaseProvider).call(
        MergeCalendarsParams(
          friendId: friendId,
          from: now,
          to: now.add(const Duration(days: 30)),
        ),
      );
});

/// 가장 가까운 추천 빈 시간 1개 (mergeCalendarProvider 결과 재사용 — RPC 중복 호출 방지)
final suggestedSlotProvider =
    FutureProvider.autoDispose.family<FreeSlotEntity?, String>((ref, friendId) async {
  final slots = await ref.watch(mergeCalendarProvider(friendId).future);
  return slots.firstOrNull;
});
