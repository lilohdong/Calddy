import 'package:calddy/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:calddy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockUser extends Mock implements User {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    mockSupabase = MockSupabaseClient();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockDataSource,
      supabase: mockSupabase,
    );
  });

  group('AuthRepositoryImpl 테스트', () {
    test('getCurrentUser는 데이터 소스에 유저가 없으면 null을 반환해야 한다', () async {
      // Arrange
      when(() => mockDataSource.currentUser).thenReturn(null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, isNull);
    });

    test('signOut은 데이터 소스의 signOut을 호출해야 한다', () async {
      // Arrange
      when(() => mockDataSource.signOut()).thenAnswer((_) async => {});

      // Act
      await repository.signOut();

      // Assert
      verify(() => mockDataSource.signOut()).called(1);
    });
  });
}
