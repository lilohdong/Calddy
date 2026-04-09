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
    test('닉네임 중복 시 DuplicateNicknameFailure를 throw한다', () {
      // PostgreSQL error code 23505 = unique_violation
      when(() => mockDataSource.completeOnboarding(
            nickname: any(named: 'nickname'),
          )).thenThrow(PostgrestException(message: 'duplicate key', code: '23505'));

      expect(
        () => repository.completeOnboarding(nickname: 'taken'),
        throwsA(isA<DuplicateNicknameFailure>()),
      );
    });

    test('refreshSession 실패 시에도 완료로 처리한다 (throw 없음)', () async {
      when(() => mockDataSource.completeOnboarding(
            nickname: any(named: 'nickname'),
          )).thenAnswer((_) async {});
      when(() => mockDataSource.refreshSession())
          .thenThrow(const AuthException('session expired'));

      // throw하지 않아야 한다
      await expectLater(
        repository.completeOnboarding(nickname: 'nick'),
        completes,
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
