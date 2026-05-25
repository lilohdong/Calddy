import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/map/data/datasources/map_remote_datasource.dart';
import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:calddy/features/map/data/models/recommendation_result_model.dart';
import 'package:calddy/features/map/data/repositories/map_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockMapRemoteDataSource extends Mock implements MapRemoteDataSource {}

final _dummyMidpoint = MidpointResultModel(
  lat: 37.5,
  lng: 127.0,
  iterationCount: 1,
  participants: const [
    ParticipantTravelModel(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyRecommendation = RecommendationResultModel(
  recommendedKeyword: '강남역',
  places: [],
);

void main() {
  late MapRepositoryImpl repository;
  late MockMapRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMapRemoteDataSource();
    repository = MapRepositoryImpl(mockDataSource);
  });

  group('calculateMidpoint', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1'))
          .thenAnswer((_) async => _dummyMidpoint);

      final result = await repository.calculateMidpoint('appt-1');

      expect(result.lat, 37.5);
      expect(result.iterationCount, 1);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => mockDataSource.calculateMidpoint('appt-1')).called(1);
    });

    test('FunctionException(404) → MapAppointmentNotFoundFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        const FunctionException(status: 404, details: 'not found'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapAppointmentNotFoundFailure>()),
      );
    });

    test('FunctionException(422) → NoLocationDataFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        const FunctionException(status: 422, details: 'no location'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<NoLocationDataFailure>()),
      );
    });

    test('FunctionException(500) → MapApiFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        const FunctionException(status: 500, details: 'internal error'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapApiFailure>()),
      );
    });

    test('미분류 예외 → MapUnknownFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1'))
          .thenThrow(Exception('unknown'));

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapUnknownFailure>()),
      );
    });
  });

  group('recommendPlace', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.recommendPlace(_dummyMidpoint))
          .thenAnswer((_) async => _dummyRecommendation);

      final result = await repository.recommendPlace(_dummyMidpoint);

      expect(result.recommendedKeyword, '강남역');
      verify(() => mockDataSource.recommendPlace(_dummyMidpoint)).called(1);
    });

    test('FunctionException(500) → MapApiFailure', () async {
      when(() => mockDataSource.recommendPlace(any())).thenThrow(
        const FunctionException(status: 500, details: 'api error'),
      );

      expect(
        () => repository.recommendPlace(_dummyMidpoint),
        throwsA(isA<MapApiFailure>()),
      );
    });
  });
}
