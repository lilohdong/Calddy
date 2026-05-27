import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../models/notification_model.dart';
import 'notification_remote_datasource.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSourceImpl({required SupabaseClient client})
      : _client = client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final userId = _currentUserId;

    final results = await _client
        .from(SupabaseConstants.notifications)
        .select('id, user_id, type, title, body, is_read, related_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (results as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from(SupabaseConstants.notifications)
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', _currentUserId);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from(SupabaseConstants.notifications)
        .delete()
        .eq('id', notificationId)
        .eq('user_id', _currentUserId);
  }

  @override
  Future<void> deleteAllNotifications() async {
    await _client
        .from(SupabaseConstants.notifications)
        .delete()
        .eq('user_id', _currentUserId);
  }
}
