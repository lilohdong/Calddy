import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.isRead,
    super.relatedId,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool,
      relatedId: json['related_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static const _dbToDart = {
    'friend_request': 'friendRequest',
    'appointment_invite': 'appointmentInvite',
    'appointment_accepted': 'appointmentAccepted',
    'appointment_rejected': 'appointmentRejected',
    'suggest_new_date': 'suggestNewDate',
    'post_liked': 'postLiked',
    'post_commented': 'postCommented',
  };

  static NotificationType _parseType(String raw) {
    final dartName = _dbToDart[raw] ?? raw;
    return NotificationType.values.firstWhere(
      (e) => e.name == dartName,
      orElse: () => NotificationType.friendRequest,
    );
  }
}
