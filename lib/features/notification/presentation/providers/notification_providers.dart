import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/delete_all_notifications_use_case.dart';
import '../../domain/usecases/delete_notification_use_case.dart';
import '../../domain/usecases/get_notifications_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';

// ── DataSource ────────────────────────────────────────────────────────────────

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(
    client: ref.watch(supabaseClientProvider),
  );
});

// ── Repository ────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final getNotificationsUseCaseProvider =
    Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(
      ref.watch(notificationRepositoryProvider));
});

final deleteNotificationUseCaseProvider =
    Provider<DeleteNotificationUseCase>((ref) {
  return DeleteNotificationUseCase(ref.watch(notificationRepositoryProvider));
});

final deleteAllNotificationsUseCaseProvider =
    Provider<DeleteAllNotificationsUseCase>((ref) {
  return DeleteAllNotificationsUseCase(
      ref.watch(notificationRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

/// 알림 목록 조회
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationEntity>>((ref) {
  return ref.read(getNotificationsUseCaseProvider).call(NoParams());
});
