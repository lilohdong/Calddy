import 'package:calddy/features/notification/data/models/notification_model.dart';
import 'package:calddy/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseJson({
  String type = 'friend_request',
  String? relatedId,
}) =>
    {
      'id': 'notif-1',
      'user_id': 'user-1',
      'type': type,
      'title': '테스트 알림',
      'body': '알림 내용',
      'is_read': false,
      'related_id': relatedId,
      'created_at': '2026-05-14T10:00:00.000Z',
    };

void main() {
  group('NotificationModel.fromJson', () {
    test('friend_request → NotificationType.friendRequest', () {
      final model = NotificationModel.fromJson(_baseJson(type: 'friend_request'));
      expect(model.type, NotificationType.friendRequest);
    });

    test('appointment_invite → NotificationType.appointmentInvite', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'appointment_invite'));
      expect(model.type, NotificationType.appointmentInvite);
    });

    test('appointment_accepted → NotificationType.appointmentAccepted', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'appointment_accepted'));
      expect(model.type, NotificationType.appointmentAccepted);
    });

    test('appointment_rejected → NotificationType.appointmentRejected', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'appointment_rejected'));
      expect(model.type, NotificationType.appointmentRejected);
    });

    test('suggest_new_date → NotificationType.suggestNewDate', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'suggest_new_date'));
      expect(model.type, NotificationType.suggestNewDate);
    });

    test('post_liked → NotificationType.postLiked', () {
      final model = NotificationModel.fromJson(_baseJson(type: 'post_liked'));
      expect(model.type, NotificationType.postLiked);
    });

    test('post_commented → NotificationType.postCommented', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'post_commented'));
      expect(model.type, NotificationType.postCommented);
    });

    test('알 수 없는 type 값은 friendRequest로 폴백한다', () {
      final model =
          NotificationModel.fromJson(_baseJson(type: 'unknown_type'));
      expect(model.type, NotificationType.friendRequest);
    });

    test('related_id가 null이면 relatedId는 null이다', () {
      final model = NotificationModel.fromJson(_baseJson(relatedId: null));
      expect(model.relatedId, isNull);
    });

    test('related_id가 있으면 relatedId에 값이 있다', () {
      final model =
          NotificationModel.fromJson(_baseJson(relatedId: 'post-42'));
      expect(model.relatedId, 'post-42');
    });

    test('createdAt이 ISO8601 문자열로 올바르게 파싱된다', () {
      final model = NotificationModel.fromJson(_baseJson());
      expect(model.createdAt, DateTime.utc(2026, 5, 14, 10));
    });

    test('is_read가 false이면 isRead는 false이다', () {
      final model = NotificationModel.fromJson(_baseJson());
      expect(model.isRead, false);
    });
  });
}
