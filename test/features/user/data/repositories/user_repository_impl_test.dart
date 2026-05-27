import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/user/data/datasources/user_remote_datasource.dart';
import 'package:calddy/features/user/data/datasources/user_remote_datasource_impl.dart'
    show NicknameOnCooldownException;
import 'package:calddy/features/user/data/models/profile_model.dart';
import 'package:calddy/features/user/data/repositories/user_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

ProfileModel _dummyProfile() => const ProfileModel(
      id: 'user-1',
      nickname: '동준',
      avatarUrl: null,
      pushEnabled: true,
    );

void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockUserRemoteDataSource();
    repository = UserRepositoryImpl(remoteDataSource: mockDataSource);
    registerFallbackValue(DateTime(2026));
  });

  // ── getProfile ───────────────────────────────────────────────────────────

  group('getProfile', () {
    test('DataSource.getProfile을 호출하고 ProfileEntity를 반환한다', () async {
      when(() => mockDataSource.getProfile('user-1'))
          .thenAnswer((_) async => _dummyProfile());

      final result = await repository.getProfile('user-1');

      expect(result.id, 'user-1');
      expect(result.nickname, '동준');
      verify(() => mockDataSource.getProfile('user-1')).called(1);
    });

    test('AuthException → UserSessionExpiredFailure', () {
      when(() => mockDataSource.getProfile(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.getProfile('user-1'),
        throwsA(isA<UserSessionExpiredFailure>()),
      );
    });

    test('PostgrestException → ProfileFetchFailure', () {
      when(() => mockDataSource.getProfile(any())).thenThrow(
        const PostgrestException(message: 'no rows', code: 'PGRST116'),
      );

      expect(
        () => repository.getProfile('user-1'),
        throwsA(isA<ProfileFetchFailure>()),
      );
    });

    test('알 수 없는 예외 → UserUnknownFailure', () {
      when(() => mockDataSource.getProfile(any()))
          .thenThrow(Exception('network'));

      expect(
        () => repository.getProfile('user-1'),
        throwsA(isA<UserUnknownFailure>()),
      );
    });
  });

  // ── updateNickname ───────────────────────────────────────────────────────

  group('updateNickname', () {
    test('DataSource.updateNickname을 1회 호출한다', () async {
      when(() => mockDataSource.updateNickname('새닉네임'))
          .thenAnswer((_) async {});

      await repository.updateNickname('새닉네임');

      verify(() => mockDataSource.updateNickname('새닉네임')).called(1);
    });

    test('AuthException → UserSessionExpiredFailure', () {
      when(() => mockDataSource.updateNickname(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.updateNickname('nick'),
        throwsA(isA<UserSessionExpiredFailure>()),
      );
    });

    test('NicknameOnCooldownException → NicknameChangeCooldownFailure', () {
      when(() => mockDataSource.updateNickname(any()))
          .thenThrow(NicknameOnCooldownException());

      expect(
        () => repository.updateNickname('nick'),
        throwsA(isA<NicknameChangeCooldownFailure>()),
      );
    });

    test('PostgrestException code 23505 → NicknameTakenFailure', () {
      when(() => mockDataSource.updateNickname(any())).thenThrow(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(
        () => repository.updateNickname('nick'),
        throwsA(isA<NicknameTakenFailure>()),
      );
    });

    test('기타 PostgrestException → ProfileUpdateFailure', () {
      when(() => mockDataSource.updateNickname(any())).thenThrow(
        const PostgrestException(message: 'RLS violation', code: '42501'),
      );

      expect(
        () => repository.updateNickname('nick'),
        throwsA(isA<ProfileUpdateFailure>()),
      );
    });
  });

  // ── updateBirthDate ──────────────────────────────────────────────────────

  group('updateBirthDate', () {
    final tDate = DateTime(1998, 6, 15);

    test('DataSource.updateBirthDate를 1회 호출한다', () async {
      when(() => mockDataSource.updateBirthDate(any()))
          .thenAnswer((_) async {});

      await repository.updateBirthDate(tDate);

      verify(() => mockDataSource.updateBirthDate(tDate)).called(1);
    });

    test('AuthException → UserSessionExpiredFailure', () {
      when(() => mockDataSource.updateBirthDate(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.updateBirthDate(tDate),
        throwsA(isA<UserSessionExpiredFailure>()),
      );
    });

    test('PostgrestException → ProfileUpdateFailure', () {
      when(() => mockDataSource.updateBirthDate(any())).thenThrow(
        const PostgrestException(message: 'RLS error', code: '42501'),
      );

      expect(
        () => repository.updateBirthDate(tDate),
        throwsA(isA<ProfileUpdateFailure>()),
      );
    });
  });

  // ── updateAvatar ─────────────────────────────────────────────────────────

  group('updateAvatar', () {
    test('DataSource.updateAvatar를 호출하고 URL을 반환한다', () async {
      when(() => mockDataSource.updateAvatar(any()))
          .thenAnswer((_) async => 'https://example.com/avatar.jpg');

      final result = await repository.updateAvatar('/tmp/photo.jpg');

      expect(result, 'https://example.com/avatar.jpg');
      verify(() => mockDataSource.updateAvatar('/tmp/photo.jpg')).called(1);
    });

    test('DataSource가 null을 반환하면 null을 반환한다', () async {
      when(() => mockDataSource.updateAvatar(any()))
          .thenAnswer((_) async => null);

      final result = await repository.updateAvatar('/tmp/photo.jpg');

      expect(result, isNull);
    });

    test('StorageException → AvatarUploadFailure', () {
      when(() => mockDataSource.updateAvatar(any()))
          .thenThrow(const StorageException('upload failed'));

      expect(
        () => repository.updateAvatar('/tmp/photo.jpg'),
        throwsA(isA<AvatarUploadFailure>()),
      );
    });

    test('PostgrestException → AvatarUploadFailure', () {
      when(() => mockDataSource.updateAvatar(any())).thenThrow(
        const PostgrestException(message: 'RLS error', code: '42501'),
      );

      expect(
        () => repository.updateAvatar('/tmp/photo.jpg'),
        throwsA(isA<AvatarUploadFailure>()),
      );
    });
  });

  // ── setPushNotification ──────────────────────────────────────────────────

  group('setPushNotification', () {
    test('DataSource.setPushNotification을 1회 호출한다', () async {
      when(() => mockDataSource.setPushNotification(
            enabled: any(named: 'enabled'),
            fcmToken: any(named: 'fcmToken'),
          )).thenAnswer((_) async {});

      await repository.setPushNotification(enabled: true, fcmToken: 'token-abc');

      verify(() => mockDataSource.setPushNotification(
            enabled: true,
            fcmToken: 'token-abc',
          )).called(1);
    });

    test('AuthException → UserSessionExpiredFailure', () {
      when(() => mockDataSource.setPushNotification(
            enabled: any(named: 'enabled'),
            fcmToken: any(named: 'fcmToken'),
          )).thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.setPushNotification(enabled: false),
        throwsA(isA<UserSessionExpiredFailure>()),
      );
    });
  });

  // ── withdraw ─────────────────────────────────────────────────────────────

  group('withdraw', () {
    test('DataSource.withdraw를 1회 호출한다', () async {
      when(() => mockDataSource.withdraw()).thenAnswer((_) async {});

      await repository.withdraw();

      verify(() => mockDataSource.withdraw()).called(1);
    });

    test('AuthException → UserSessionExpiredFailure', () {
      when(() => mockDataSource.withdraw())
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.withdraw(),
        throwsA(isA<UserSessionExpiredFailure>()),
      );
    });

    test('알 수 없는 예외 → WithdrawFailure', () {
      when(() => mockDataSource.withdraw()).thenThrow(Exception('network'));

      expect(
        () => repository.withdraw(),
        throwsA(isA<WithdrawFailure>()),
      );
    });
  });
}
