import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:calddy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockUser extends Mock implements User {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockDataSource);
    registerFallbackValue(DateTime(2024));
  });

  // ── getCurrentUser ────────────────────────────────────────────
  group('getCurrentUser', () {
    test('데이터 소스에 유저가 없으면 null을 반환한다', () async {
      when(() => mockDataSource.currentUser).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });
  });

  // ── signOut ───────────────────────────────────────────────────
  group('signOut', () {
    test('데이터 소스의 signOut을 1회 호출한다', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockDataSource.signOut()).called(1);
    });

    test('AuthException 발생 시 AuthFailure로 변환하여 throw한다', () {
      when(() => mockDataSource.signOut())
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.signOut(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  // ── signInWithGoogle ─────────────────────────────────────────
  group('signInWithGoogle', () {
    test('취소 시 GoogleSignInCancelledFailure를 throw한다', () {
      when(() => mockDataSource.signInWithGoogle())
          .thenThrow(const AuthException('google_sign_in_cancelled'));

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<GoogleSignInCancelledFailure>()),
      );
    });

    test('GOOGLE_WEB_CLIENT_ID 미설정 시 GoogleConfigMissingFailure를 throw한다', () {
      when(() => mockDataSource.signInWithGoogle())
          .thenThrow(const AuthException('google_config_missing'));

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<GoogleConfigMissingFailure>()),
      );
    });

    test('토큰 취득 실패 시 NetworkFailure를 throw한다', () {
      when(() => mockDataSource.signInWithGoogle())
          .thenThrow(const AuthException('google_token_fetch_failed'));

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  // ── signInWithEmail ──────────────────────────────────────────
  group('signInWithEmail', () {
    test('잘못된 자격증명 시 InvalidCredentialsFailure를 throw한다', () {
      when(() => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => repository.signInWithEmail(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('이메일 미인증 시 EmailNotConfirmedFailure를 throw한다', () {
      when(() => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException('Email not confirmed'));

      expect(
        () => repository.signInWithEmail(email: 'a@b.com', password: 'pass'),
        throwsA(isA<EmailNotConfirmedFailure>()),
      );
    });
  });

  // ── signUpWithEmail ──────────────────────────────────────────
  group('signUpWithEmail', () {
    test('이메일 중복 시 EmailAlreadyInUseFailure를 throw한다', () {
      when(() => mockDataSource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException('User already registered'));

      expect(
        () => repository.signUpWithEmail(email: 'dup@b.com', password: 'pass'),
        throwsA(isA<EmailAlreadyInUseFailure>()),
      );
    });
  });

  // ── completeOnboarding ───────────────────────────────────────
  group('completeOnboarding', () {
    final tNow = DateTime(2026, 5, 14);

    test('닉네임 중복 시 DuplicateNicknameFailure를 throw한다', () {
      when(() => mockDataSource.completeOnboarding(
            nickname: any(named: 'nickname'),
            termsAgreedAt: any(named: 'termsAgreedAt'),
            termsVersion: any(named: 'termsVersion'),
          )).thenThrow(PostgrestException(message: 'duplicate key', code: '23505'));

      expect(
        () => repository.completeOnboarding(
          nickname: 'taken',
          termsAgreedAt: tNow,
          termsVersion: '1.0',
        ),
        throwsA(isA<DuplicateNicknameFailure>()),
      );
    });

    test('refreshSession 실패 시에도 완료로 처리한다 (throw 없음)', () async {
      when(() => mockDataSource.completeOnboarding(
            nickname: any(named: 'nickname'),
            termsAgreedAt: any(named: 'termsAgreedAt'),
            termsVersion: any(named: 'termsVersion'),
          )).thenAnswer((_) async {});
      when(() => mockDataSource.refreshSession())
          .thenThrow(const AuthException('session expired'));

      await expectLater(
        repository.completeOnboarding(
          nickname: 'nick',
          termsAgreedAt: tNow,
          termsVersion: '1.0',
        ),
        completes,
      );
    });
  });

  // ── sendOtp ──────────────────────────────────────────────────
  group('sendOtp', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.sendOtp(any()))
          .thenAnswer((_) async {});

      await expectLater(
        repository.sendOtp('user@test.com'),
        completes,
      );
    });

    test('요청 초과 시 TooManyRequestsFailure를 throw한다', () {
      when(() => mockDataSource.sendOtp(any()))
          .thenThrow(const AuthException('too many requests', statusCode: '429'));

      expect(
        () => repository.sendOtp('user@test.com'),
        throwsA(isA<TooManyRequestsFailure>()),
      );
    });
  });

  // ── verifyOtp ─────────────────────────────────────────────────
  group('verifyOtp', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenAnswer((_) async {});

      await expectLater(
        repository.verifyOtp(email: 'user@test.com', token: '123456'),
        completes,
      );
    });

    test('만료된 토큰 시 OtpExpiredFailure를 throw한다', () {
      when(() => mockDataSource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenThrow(const AuthException('otp_expired'));

      expect(
        () => repository.verifyOtp(email: 'user@test.com', token: '000000'),
        throwsA(isA<OtpExpiredFailure>()),
      );
    });

    test('잘못된 토큰 시 InvalidOtpFailure를 throw한다', () {
      when(() => mockDataSource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenThrow(const AuthException('invalid token'));

      expect(
        () => repository.verifyOtp(email: 'user@test.com', token: '999999'),
        throwsA(isA<InvalidOtpFailure>()),
      );
    });
  });

  // ── updatePassword ───────────────────────────────────────────
  group('updatePassword', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.updatePassword(any()))
          .thenAnswer((_) async {});

      await expectLater(
        repository.updatePassword('NewPass@123'),
        completes,
      );
      verify(() => mockDataSource.updatePassword('NewPass@123')).called(1);
    });

    test('약한 비밀번호 → WeakPasswordFailure', () {
      when(() => mockDataSource.updatePassword(any())).thenThrow(
        const AuthException('Password should be at least 6 chars'),
      );

      expect(
        () => repository.updatePassword('weak'),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('이전 비밀번호와 동일 → SamePasswordFailure', () {
      when(() => mockDataSource.updatePassword(any()))
          .thenThrow(const AuthException('same password'));

      expect(
        () => repository.updatePassword('SamePass@1'),
        throwsA(isA<SamePasswordFailure>()),
      );
    });

    test('세션 만료 → SessionExpiredAuthFailure', () {
      when(() => mockDataSource.updatePassword(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.updatePassword('Pass@1234'),
        throwsA(isA<SessionExpiredAuthFailure>()),
      );
    });

    test('요청 초과 → TooManyRequestsFailure', () {
      when(() => mockDataSource.updatePassword(any())).thenThrow(
        const AuthException('too many requests', statusCode: '429'),
      );

      expect(
        () => repository.updatePassword('Pass@1234'),
        throwsA(isA<TooManyRequestsFailure>()),
      );
    });

    test('알 수 없는 예외 → UnknownAuthFailure', () {
      when(() => mockDataSource.updatePassword(any()))
          .thenThrow(Exception('unknown'));

      expect(
        () => repository.updatePassword('Pass@1234'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });
  });

  // ── sendPasswordResetEmail ───────────────────────────────────
  group('sendPasswordResetEmail', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await expectLater(
        repository.sendPasswordResetEmail('user@test.com'),
        completes,
      );
    });

    test('네트워크 오류 시 NetworkFailure를 throw한다', () {
      when(() => mockDataSource.sendPasswordResetEmail(any()))
          .thenThrow(const AuthException('network connection timeout'));

      expect(
        () => repository.sendPasswordResetEmail('user@test.com'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
