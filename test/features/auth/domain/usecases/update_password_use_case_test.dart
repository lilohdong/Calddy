import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:calddy/features/auth/domain/usecases/update_password_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UpdatePasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdatePasswordUseCase(mockRepository);
  });

  group('UpdatePasswordUseCase', () {
    test('유효한 비밀번호 → repository.updatePassword 1회 호출', () async {
      when(() => mockRepository.updatePassword(any()))
          .thenAnswer((_) async {});

      await useCase(const UpdatePasswordParams(newPassword: 'Valid@123'));

      verify(() => mockRepository.updatePassword('Valid@123')).called(1);
    });

    test('공백 포함 비밀번호 → PasswordValidationFailure throw (repository 미호출)',
        () {
      expect(
        () => useCase(const UpdatePasswordParams(newPassword: 'pass word1!')),
        throwsA(isA<PasswordValidationFailure>()),
      );
      verifyNever(() => mockRepository.updatePassword(any()));
    });

    test('8자 미만 비밀번호 → PasswordValidationFailure throw', () {
      expect(
        () => useCase(const UpdatePasswordParams(newPassword: 'Ab@1234')),
        throwsA(isA<PasswordValidationFailure>()),
      );
      verifyNever(() => mockRepository.updatePassword(any()));
    });

    test('특수문자 없는 비밀번호 → PasswordValidationFailure throw', () {
      expect(
        () => useCase(const UpdatePasswordParams(newPassword: 'Password123')),
        throwsA(isA<PasswordValidationFailure>()),
      );
      verifyNever(() => mockRepository.updatePassword(any()));
    });

    test('repository에서 throw한 예외는 그대로 전파된다', () {
      when(() => mockRepository.updatePassword(any()))
          .thenThrow(const WeakPasswordFailure());

      expect(
        () => useCase(const UpdatePasswordParams(newPassword: 'Valid@123')),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });
  });
}
