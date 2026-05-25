import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/map/data/datasources/map_remote_datasource.dart';
import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:calddy/features/map/data/repositories/map_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:functions_client/functions_client.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRemoteDataSource extends Mock implements MapRemoteDataSource {}

MidpointResultModel _dummyMidpoint() => const MidpointResultModel(
      lat: 37.5,
      lng: 127.0,
      participants: [],
    );

PlaceModel _dummyPlace() => const PlaceModel(
      placeId: 'place-1',
      name: '스타벅스',
      address: '서울 강남구',
      lat: 37.5,
      lng: 127.0,
      distanceFromMidpoint: 100.0,
    );

void main() {
  late MapRepositoryImpl repository;
  late MockMapRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMapRemoteDataSource();
    repository = MapRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // ── calculateMidpoint ────────────────────────────────────────────────────

  group('calculateMidpoint', () {
    test('성공 시 MidpointResultEntity를 반환한다', () async {
      when(() => mockDataSource.calculateMidpoint(any()))
          .thenAnswer((_) async => _dummyMidpoint());

      final result = await repository.calculateMidpoint('appt-1');

      expect(result.lat, 37.5);
      expect(result.lng, 127.0);
    });

    test('FunctionException — not found 메시지 → MapAppointmentNotFoundFailure', () async {
      when(() => mockDataSource.calculateMidpoint(any())).thenThrow(
        FunctionException(
          status: 404,
          details: {'error': 'appointment not found'},
        ),
      );

      expect(
        () => repository.calculateMidpoint('bad-id'),
        throwsA(isA<MapAppointmentNotFoundFailure>()),
      );
    });

    test('FunctionException — 일반 서버 오류 → MapServerFailure', () async {
      when(() => mockDataSource.calculateMidpoint(any())).thenThrow(
        FunctionException(
          status: 500,
          details: {'error': 'internal server error'},
        ),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapServerFailure>()),
      );
    });

    test('예상치 못한 예외 → MapUnknownFailure', () async {
      when(() => mockDataSource.calculateMidpoint(any()))
          .thenThrow(Exception('network error'));

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapUnknownFailure>()),
      );
    });
  });

  // ── searchPlaces ─────────────────────────────────────────────────────────

  group('searchPlaces', () {
    test('성공 시 List<PlaceEntity>를 반환한다', () async {
      when(() => mockDataSource.searchPlaces(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            keyword: any(named: 'keyword'),
            radius: any(named: 'radius'),
          )).thenAnswer((_) async => [_dummyPlace()]);

      final result = await repository.searchPlaces(lat: 37.5, lng: 127.0);

      expect(result.length, 1);
      expect(result.first.name, '스타벅스');
    });

    test('FunctionException → MapServerFailure', () async {
      when(() => mockDataSource.searchPlaces(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            keyword: any(named: 'keyword'),
            radius: any(named: 'radius'),
          )).thenThrow(
        FunctionException(
          status: 500,
          details: {'error': 'Google Maps API error'},
        ),
      );

      expect(
        () => repository.searchPlaces(lat: 37.5, lng: 127.0),
        throwsA(isA<MapServerFailure>()),
      );
    });

    test('예상치 못한 예외 → MapUnknownFailure', () async {
      when(() => mockDataSource.searchPlaces(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            keyword: any(named: 'keyword'),
            radius: any(named: 'radius'),
          )).thenThrow(Exception('timeout'));

      expect(
        () => repository.searchPlaces(lat: 37.5, lng: 127.0),
        throwsA(isA<MapUnknownFailure>()),
      );
    });
  });
}
