import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    try {
      return await _remoteDataSource.getNotifications();
    } on AuthException {
      throw const NotificationSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw NotificationDatabaseFailure(e.message);
    } catch (_) {
      throw const NotificationFetchFailure();
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _remoteDataSource.markAsRead(notificationId);
    } on AuthException {
      throw const NotificationSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw NotificationDatabaseFailure(e.message);
    } catch (_) {
      throw const NotificationUpdateFailure();
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _remoteDataSource.deleteNotification(notificationId);
    } on AuthException {
      throw const NotificationSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw NotificationDatabaseFailure(e.message);
    } catch (_) {
      throw const NotificationDeleteFailure();
    }
  }

  @override
  Future<void> deleteAllNotifications() async {
    try {
      await _remoteDataSource.deleteAllNotifications();
    } on AuthException {
      throw const NotificationSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw NotificationDatabaseFailure(e.message);
    } catch (_) {
      throw const NotificationDeleteFailure();
    }
  }
}
