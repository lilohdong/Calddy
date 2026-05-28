import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/delete_notification_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';
import '../providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: () => ref.invalidate(notificationsProvider),
            child: const Text('새로고침'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(e is NotificationFailure ? e.message : '불러오기 실패',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('새로운 알림이 없습니다.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotificationTile(
                notification: notifications[i],
                onMarkRead: () async {
                  try {
                    await ref
                        .read(markNotificationReadUseCaseProvider)
                        .call(MarkNotificationReadParams(
                            notificationId: notifications[i].id));
                    ref.invalidate(notificationsProvider);
                  } catch (_) {}
                },
                onDelete: () async {
                  try {
                    await ref
                        .read(deleteNotificationUseCaseProvider)
                        .call(DeleteNotificationParams(
                            notificationId: notifications[i].id));
                    ref.invalidate(notificationsProvider);
                  } catch (_) {}
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  final NotificationEntity notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: InkWell(
        onTap: notification.isRead ? null : onMarkRead,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : Colors.deepPurple.shade100,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey.shade100
                      : Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(notification.type),
                  color: notification.isRead
                      ? Colors.grey
                      : Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType type) => switch (type) {
        NotificationType.friendRequest => Icons.person_add_outlined,
        NotificationType.appointmentInvite => Icons.event_outlined,
        NotificationType.appointmentAccepted => Icons.check_circle_outline,
        NotificationType.appointmentRejected => Icons.cancel_outlined,
        NotificationType.suggestNewDate => Icons.event_repeat_outlined,
        NotificationType.postLiked => Icons.favorite_outline,
        NotificationType.postCommented => Icons.chat_bubble_outline,
      };
}
