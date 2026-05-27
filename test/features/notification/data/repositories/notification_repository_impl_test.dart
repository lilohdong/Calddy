import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:calddy/features/notification/data/models/notification_model.dart';
import 'package:calddy/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:calddy/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

NotificationModel _dummyNotification({String id = 'notif-1'}) =>
    NotificationModel(
      id: id,
      userId: 'user-1',
      type: NotificationType.friendRequest,
      title: '친구 요청',
      body: '누군가 친구 요청을 보냈습니다.',
      isRead: false,
      createdAt: DateTime(2026, 5, 14),
    );

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNotificationRemoteDataSource();
    repository = NotificationRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // ── getNotifications ─────────────────────────────────────────────────────

  group('getNotifications', () {
    test('DataSource 결과를 List<NotificationEntity>로 반환한다', () async {
      when(() => mockDataSource.getNotifications())
          .thenAnswer((_) async => [_dummyNotification()]);

      final result = await repository.getNotifications();

      expect(result.length, 1);
      expect(result.first.type, NotificationType.friendRequest);
      verify(() => mockDataSource.getNotifications()).called(1);
    });

    test('AuthException → NotificationSessionExpiredFailure', () {
      when(() => mockDataSource.getNotifications())
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.getNotifications(),
        throwsA(isA<NotificationSessionExpiredFailure>()),
      );
    });

    test('PostgrestException → NotificationDatabaseFailure', () {
      when(() => mockDataSource.getNotifications()).thenThrow(
        const PostgrestException(message: 'RLS violation', code: '42501'),
      );

      expect(
        () => repository.getNotifications(),
        throwsA(isA<NotificationDatabaseFailure>()),
      );
    });

    test('알 수 없는 예외 → NotificationFetchFailure', () {
      when(() => mockDataSource.getNotifications())
          .thenThrow(Exception('unknown'));

      expect(
        () => repository.getNotifications(),
        throwsA(isA<NotificationFetchFailure>()),
      );
    });
  });

  // ── markAsRead ───────────────────────────────────────────────────────────

  group('markAsRead', () {
    test('DataSource.markAsRead를 1회 호출한다', () async {
      when(() => mockDataSource.markAsRead('notif-1'))
          .thenAnswer((_) async {});

      await repository.markAsRead('notif-1');

      verify(() => mockDataSource.markAsRead('notif-1')).called(1);
    });

    test('AuthException → NotificationSessionExpiredFailure', () {
      when(() => mockDataSource.markAsRead(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.markAsRead('notif-1'),
        throwsA(isA<NotificationSessionExpiredFailure>()),
      );
    });

    test('PostgrestException → NotificationDatabaseFailure', () {
      when(() => mockDataSource.markAsRead(any())).thenThrow(
        const PostgrestException(message: 'no rows', code: 'PGRST116'),
      );

      expect(
        () => repository.markAsRead('notif-1'),
        throwsA(isA<NotificationDatabaseFailure>()),
      );
    });

    test('알 수 없는 예외 → NotificationUpdateFailure', () {
      when(() => mockDataSource.markAsRead(any()))
          .thenThrow(Exception('network'));

      expect(
        () => repository.markAsRead('notif-1'),
        throwsA(isA<NotificationUpdateFailure>()),
      );
    });
  });

  // ── deleteNotification ───────────────────────────────────────────────────

  group('deleteNotification', () {
    test('DataSource.deleteNotification을 1회 호출한다', () async {
      when(() => mockDataSource.deleteNotification('notif-1'))
          .thenAnswer((_) async {});

      await repository.deleteNotification('notif-1');

      verify(() => mockDataSource.deleteNotification('notif-1')).called(1);
    });

    test('AuthException → NotificationSessionExpiredFailure', () {
      when(() => mockDataSource.deleteNotification(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.deleteNotification('notif-1'),
        throwsA(isA<NotificationSessionExpiredFailure>()),
      );
    });

    test('알 수 없는 예외 → NotificationDeleteFailure', () {
      when(() => mockDataSource.deleteNotification(any()))
          .thenThrow(Exception('network'));

      expect(
        () => repository.deleteNotification('notif-1'),
        throwsA(isA<NotificationDeleteFailure>()),
      );
    });
  });

  // ── deleteAllNotifications ───────────────────────────────────────────────

  group('deleteAllNotifications', () {
    test('DataSource.deleteAllNotifications를 1회 호출한다', () async {
      when(() => mockDataSource.deleteAllNotifications())
          .thenAnswer((_) async {});

      await repository.deleteAllNotifications();

      verify(() => mockDataSource.deleteAllNotifications()).called(1);
    });

    test('AuthException → NotificationSessionExpiredFailure', () {
      when(() => mockDataSource.deleteAllNotifications())
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.deleteAllNotifications(),
        throwsA(isA<NotificationSessionExpiredFailure>()),
      );
    });

    test('알 수 없는 예외 → NotificationDeleteFailure', () {
      when(() => mockDataSource.deleteAllNotifications())
          .thenThrow(Exception('unknown'));

      expect(
        () => repository.deleteAllNotifications(),
        throwsA(isA<NotificationDeleteFailure>()),
      );
    });
  });
}
