import 'package:calddy/features/map/domain/entities/midpoint_result_entity.dart';
import 'package:calddy/features/map/domain/entities/place_entity.dart';
import 'package:calddy/features/map/domain/repositories/map_repository.dart';
import 'package:calddy/features/map/domain/usecases/calculate_midpoint_usecase.dart';
import 'package:calddy/features/map/domain/usecases/search_places_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepository extends Mock implements MapRepository {}

const _dummyMidpoint = MidpointResultEntity(
  lat: 37.5,
  lng: 127.0,
  participants: [
    ParticipantTravelEntity(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyPlace = PlaceEntity(
  placeId: 'p1',
  name: '스타벅스 강남점',
  address: '서울시 강남구',
  lat: 37.498,
  lng: 127.027,
  distanceFromMidpoint: 350.0,
);

void main() {
  late MockMapRepository repo;

  setUp(() {
    repo = MockMapRepository();
  });

  group('CalculateMidpointUseCase', () {
    test('repository.calculateMidpoint을 1회 호출하고 결과를 반환한다', () async {
      when(() => repo.calculateMidpoint('appt-1'))
          .thenAnswer((_) async => _dummyMidpoint);

      final useCase = CalculateMidpointUseCase(repo);
      final result = await useCase(
        const CalculateMidpointParams(appointmentId: 'appt-1'),
      );

      expect(result.lat, 37.5);
      expect(result.participants.length, 1);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => repo.calculateMidpoint('appt-1')).called(1);
    });
  });

  group('SearchPlacesUseCase', () {
    test('repository.searchPlaces를 1회 호출하고 결과를 반환한다', () async {
      when(() => repo.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).thenAnswer((_) async => [_dummyPlace]);

      final useCase = SearchPlacesUseCase(repo);
      final result = await useCase(
        const SearchPlacesParams(lat: 37.5, lng: 127.0, keyword: '카페'),
      );

      expect(result.length, 1);
      expect(result.first.name, '스타벅스 강남점');
      verify(() => repo.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).called(1);
    });
  });
}
