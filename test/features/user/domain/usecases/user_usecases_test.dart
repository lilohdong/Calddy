import 'package:calddy/core/usecase/usecase.dart';
import 'package:calddy/features/user/domain/entities/profile_entity.dart';
import 'package:calddy/features/user/domain/repositories/user_repository.dart';
import 'package:calddy/features/user/domain/usecases/get_profile_use_case.dart';
import 'package:calddy/features/user/domain/usecases/set_push_notification_use_case.dart';
import 'package:calddy/features/user/domain/usecases/update_avatar_use_case.dart';
import 'package:calddy/features/user/domain/usecases/update_birth_date_use_case.dart';
import 'package:calddy/features/user/domain/usecases/update_nickname_use_case.dart';
import 'package:calddy/features/user/domain/usecases/withdraw_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

const _dummyProfile = ProfileEntity(id: 'user-1', nickname: '동준');

void main() {
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    registerFallbackValue(DateTime(2026));
  });

  // ── GetProfileUseCase ────────────────────────────────────────────────────

  group('GetProfileUseCase', () {
    test('repository.getProfile을 userId와 함께 호출하고 ProfileEntity를 반환한다',
        () async {
      when(() => mockRepository.getProfile('user-1'))
          .thenAnswer((_) async => _dummyProfile);

      final useCase = GetProfileUseCase(mockRepository);
      final result =
          await useCase(const GetProfileParams(userId: 'user-1'));

      expect(result.id, 'user-1');
      expect(result.nickname, '동준');
      verify(() => mockRepository.getProfile('user-1')).called(1);
    });
  });

  // ── UpdateNicknameUseCase ────────────────────────────────────────────────

  group('UpdateNicknameUseCase', () {
    test('repository.updateNickname을 1회 호출한다', () async {
      when(() => mockRepository.updateNickname('새닉네임'))
          .thenAnswer((_) async {});

      final useCase = UpdateNicknameUseCase(mockRepository);
      await useCase(const UpdateNicknameParams(nickname: '새닉네임'));

      verify(() => mockRepository.updateNickname('새닉네임')).called(1);
    });
  });

  // ── UpdateBirthDateUseCase ───────────────────────────────────────────────

  group('UpdateBirthDateUseCase', () {
    test('repository.updateBirthDate를 1회 호출한다', () async {
      final tDate = DateTime(1998, 6, 15);
      when(() => mockRepository.updateBirthDate(any()))
          .thenAnswer((_) async {});

      final useCase = UpdateBirthDateUseCase(mockRepository);
      await useCase(UpdateBirthDateParams(birthDate: tDate));

      verify(() => mockRepository.updateBirthDate(tDate)).called(1);
    });
  });

  // ── UpdateAvatarUseCase ──────────────────────────────────────────────────

  group('UpdateAvatarUseCase', () {
    test('repository.updateAvatar를 호출하고 URL을 반환한다', () async {
      when(() => mockRepository.updateAvatar(any()))
          .thenAnswer((_) async => 'https://example.com/avatar.jpg');

      final useCase = UpdateAvatarUseCase(mockRepository);
      final result =
          await useCase(const UpdateAvatarParams(filePath: '/tmp/photo.jpg'));

      expect(result, 'https://example.com/avatar.jpg');
      verify(() => mockRepository.updateAvatar('/tmp/photo.jpg')).called(1);
    });

    test('repository가 null을 반환하면 null을 반환한다', () async {
      when(() => mockRepository.updateAvatar(any()))
          .thenAnswer((_) async => null);

      final useCase = UpdateAvatarUseCase(mockRepository);
      final result =
          await useCase(const UpdateAvatarParams(filePath: '/tmp/photo.jpg'));

      expect(result, isNull);
    });
  });

  // ── SetPushNotificationUseCase ───────────────────────────────────────────

  group('SetPushNotificationUseCase', () {
    test('enabled=true, fcmToken 포함하여 repository를 호출한다', () async {
      when(() => mockRepository.setPushNotification(
            enabled: any(named: 'enabled'),
            fcmToken: any(named: 'fcmToken'),
          )).thenAnswer((_) async {});

      final useCase = SetPushNotificationUseCase(mockRepository);
      await useCase(
        const SetPushNotificationParams(enabled: true, fcmToken: 'token-abc'),
      );

      verify(() => mockRepository.setPushNotification(
            enabled: true,
            fcmToken: 'token-abc',
          )).called(1);
    });

    test('enabled=false, fcmToken null로 repository를 호출한다', () async {
      when(() => mockRepository.setPushNotification(
            enabled: any(named: 'enabled'),
            fcmToken: any(named: 'fcmToken'),
          )).thenAnswer((_) async {});

      final useCase = SetPushNotificationUseCase(mockRepository);
      await useCase(const SetPushNotificationParams(enabled: false));

      verify(() => mockRepository.setPushNotification(
            enabled: false,
            fcmToken: null,
          )).called(1);
    });
  });

  // ── WithdrawUseCase ──────────────────────────────────────────────────────

  group('WithdrawUseCase', () {
    test('repository.withdraw를 1회 호출한다', () async {
      when(() => mockRepository.withdraw()).thenAnswer((_) async {});

      final useCase = WithdrawUseCase(mockRepository);
      await useCase(NoParams());

      verify(() => mockRepository.withdraw()).called(1);
    });
  });
}
