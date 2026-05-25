import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/calendar/data/datasources/drawing_remote_datasource.dart';
import 'package:calddy/features/calendar/data/models/drawing_model.dart';
import 'package:calddy/features/calendar/data/repositories/drawing_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDrawingRemoteDataSource extends Mock
    implements DrawingRemoteDataSource {}

class FakeDrawingModel extends Fake implements DrawingModel {}

DrawingModel _dummyModel() => DrawingModel(
      id: 'drawing-1',
      userId: 'user-1',
      drawDate: DateTime(2026, 5, 7),
      strokes: const [],
      updatedAt: DateTime(2026, 5, 7, 10),
    );

void main() {
  late DrawingRepositoryImpl repository;
  late MockDrawingRemoteDataSource mockDataSource;

  setUpAll(() => registerFallbackValue(FakeDrawingModel()));

  setUp(() {
    mockDataSource = MockDrawingRemoteDataSource();
    repository = DrawingRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('saveDrawing', () {
    test('DataSource.saveDrawing을 1회 호출하고 DrawingEntity를 반환한다', () async {
      final model = _dummyModel();
      when(() => mockDataSource.saveDrawing(any()))
          .thenAnswer((_) async => model);

      final result = await repository.saveDrawing(model);

      expect(result.id, 'drawing-1');
      verify(() => mockDataSource.saveDrawing(any())).called(1);
    });

    test('AuthException → DrawingSessionExpiredFailure 변환', () async {
      when(() => mockDataSource.saveDrawing(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.saveDrawing(_dummyModel()),
        throwsA(isA<DrawingSessionExpiredFailure>()),
      );
    });
  });

  group('getDrawingByDate', () {
    test('해당 날짜 Drawing이 있으면 DrawingEntity를 반환한다', () async {
      final date = DateTime(2026, 5, 7);
      when(() => mockDataSource.getDrawingByDate(date))
          .thenAnswer((_) async => _dummyModel());

      final result = await repository.getDrawingByDate(date);

      expect(result, isNotNull);
      expect(result!.drawDate, date);
    });

    test('해당 날짜 Drawing이 없으면 null을 반환한다', () async {
      final date = DateTime(2026, 5, 8);
      when(() => mockDataSource.getDrawingByDate(date))
          .thenAnswer((_) async => null);

      final result = await repository.getDrawingByDate(date);

      expect(result, isNull);
    });
  });
}
