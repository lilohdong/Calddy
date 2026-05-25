import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/map/data/datasources/map_remote_datasource.dart';
import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:calddy/features/map/data/repositories/map_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockMapRemoteDataSource extends Mock implements MapRemoteDataSource {}

const _dummyMidpoint = MidpointResultModel(
  lat: 37.5,
  lng: 127.0,
  participants: [
    ParticipantTravelModel(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyPlace = PlaceModel(
  placeId: 'p1',
  name: '스타벅스 강남점',
  address: '서울시 강남구',
  lat: 37.498,
  lng: 127.027,
);

void main() {
  late MapRepositoryImpl repository;
  late MockMapRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMapRemoteDataSource();
    repository = MapRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('calculateMidpoint', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1'))
          .thenAnswer((_) async => _dummyMidpoint);

      final result = await repository.calculateMidpoint('appt-1');

      expect(result.lat, 37.5);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => mockDataSource.calculateMidpoint('appt-1')).called(1);
    });

    test('FunctionException(404) → MapAppointmentNotFoundFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        FunctionException(status: 404, details: 'not found'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapAppointmentNotFoundFailure>()),
      );
    });

    test('FunctionException(500) → MapServerFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        FunctionException(status: 500, details: 'internal error'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapServerFailure>()),
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

  group('searchPlaces', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).thenAnswer((_) async => [_dummyPlace]);

      final result = await repository.searchPlaces(
        lat: 37.5,
        lng: 127.0,
        keyword: '카페',
      );

      expect(result.length, 1);
      expect(result.first.name, '스타벅스 강남점');
    });

    test('FunctionException(500) → MapServerFailure', () async {
      when(() => mockDataSource.searchPlaces(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            keyword: any(named: 'keyword'),
            radius: any(named: 'radius'),
          )).thenThrow(FunctionException(status: 500, details: 'api error'));

      expect(
        () => repository.searchPlaces(lat: 37.5, lng: 127.0),
        throwsA(isA<MapServerFailure>()),
      );
    });
  });
}
