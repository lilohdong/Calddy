enum NotificationType {
  friendRequest,
  appointmentInvite,
  appointmentAccepted,
  appointmentRejected,
  suggestNewDate,
  postLiked,
  postCommented,
}

class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });
}
